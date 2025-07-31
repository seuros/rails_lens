# frozen_string_literal: true

require 'concurrent'

module RailsLens
  class ModelDetector
    class << self
      def detect_models(options = {})
        # Always eager load all models
        eager_load_models

        # Find all ActiveRecord models (always use ActiveRecord::Base as it's always defined)
        models = find_descendants_of(ActiveRecord::Base)

        # Filter and sort models
        models = filter_models(models, options)
        models.sort_by { |model| model.name || '' }
      end

      def model_for_table(table_name)
        detect_models.find { |model| model.table_name == table_name }
      end

      def abstract_models
        detect_models.select(&:abstract_class?)
      end

      def concrete_models
        detect_models.reject(&:abstract_class?)
      end

      def sti_base_models
        concrete_models.select { |model| has_sti_column?(model) }
      end

      def sti_child_models
        concrete_models.select { |model| model.superclass != ActiveRecord::Base && concrete_models.include?(model.superclass) }
      end

      def view_backed_models
        detect_models.select { |model| view_exists?(model) }
      end

      def table_backed_models
        detect_models.reject { |model| view_exists?(model) }
      end

      def view_exists?(model_class)
        return false if model_class.abstract_class?
        return false unless model_class.table_name

        # Cache view existence checks for performance
        @view_cache ||= {}
        cache_key = "#{model_class.connection.object_id}_#{model_class.table_name}"

        return @view_cache[cache_key] if @view_cache.key?(cache_key)

        @view_cache[cache_key] = check_view_existence(model_class)
      end

      private

      def check_view_existence(model_class)
        connection = model_class.connection
        table_name = model_class.table_name

        case connection.adapter_name.downcase
        when 'postgresql'
          check_postgresql_view(connection, table_name)
        when 'mysql', 'mysql2'
          check_mysql_view(connection, table_name)
        when 'sqlite', 'sqlite3'
          check_sqlite_view(connection, table_name)
        else
          false # Unsupported adapter
        end
      rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotDefined
        false # If we can't check, assume it's not a view
      end

      # rubocop:disable Naming/PredicateMethod
      def check_postgresql_view(connection, table_name)
        # Check both regular views and materialized views
        result = connection.exec_query(<<~SQL.squish, 'Check PostgreSQL View')
          SELECT 1 FROM information_schema.views#{' '}
          WHERE table_name = '#{connection.quote_string(table_name)}'
          UNION ALL
          SELECT 1 FROM pg_matviews#{' '}
          WHERE matviewname = '#{connection.quote_string(table_name)}'
          LIMIT 1
        SQL
        result.rows.any?
      end

      def check_mysql_view(connection, table_name)
        result = connection.exec_query(<<~SQL.squish, 'Check MySQL View')
          SELECT 1 FROM information_schema.views#{' '}
          WHERE table_name = '#{connection.quote_string(table_name)}'
          AND table_schema = DATABASE()
          LIMIT 1
        SQL
        result.rows.any?
      end

      def check_sqlite_view(connection, table_name)
        result = connection.exec_query(<<~SQL.squish, 'Check SQLite View')
          SELECT 1 FROM sqlite_master#{' '}
          WHERE type = 'view' AND name = '#{connection.quote_string(table_name)}'
          LIMIT 1
        SQL
        result.rows.any?
      end
      # rubocop:enable Naming/PredicateMethod

      def eager_load_models
        # Zeitwerk is always available in Rails 7+
        Zeitwerk::Loader.eager_load_all
      end

      def find_descendants_of(base_class)
        base_class.descendants.select do |klass|
          klass.name && !klass.name.start_with?('HABTM_')
        end
      end

      def filter_models(models, options)
        # Data provenance trace - log filtering decisions
        trace_filtering = options[:trace_filtering] || ENV.fetch('RAILS_LENS_TRACE_FILTERING', nil)

        original_count = models.size
        Rails.logger.debug { "[ModelDetector] Starting with #{original_count} models" } if trace_filtering

        # Remove anonymous classes and non-class objects
        before_count = models.size
        models = models.select { |model| model.is_a?(Class) && model.name.present? }
        log_filter_step('Anonymous/unnamed class removal', before_count, models.size, trace_filtering)

        # Filter by namespace if specified
        if options[:namespace]
          namespace = options[:namespace].to_s
          before_count = models.size
          models = models.select { |model| model.name.start_with?(namespace) }
          log_filter_step("Namespace filter (#{namespace})", before_count, models.size, trace_filtering)
        end

        # Exclude specific models
        if options[:exclude]
          exclude_patterns = Array(options[:exclude])
          before_count = models.size
          models = models.reject do |model|
            excluded = exclude_patterns.any? do |pattern|
              case pattern
              when Regexp
                model.name.match?(pattern)
              when String
                model.name == pattern || model.table_name == pattern
              else
                false
              end
            end
            if excluded && trace_filtering
              Rails.logger.debug do
                "[ModelDetector] Excluding #{model.name}: matched exclude pattern"
              end
            end
            excluded
          end
          log_filter_step('Exclude patterns', before_count, models.size, trace_filtering)
        end

        # Include only specific models
        if options[:include]
          include_patterns = Array(options[:include])
          before_count = models.size
          models = models.select do |model|
            included = include_patterns.any? do |pattern|
              case pattern
              when Regexp
                model.name.match?(pattern)
              when String
                model.name == pattern || model.table_name == pattern
              else
                false
              end
            end
            if included && trace_filtering
              Rails.logger.debug do
                "[ModelDetector] Including #{model.name}: matched include pattern"
              end
            end
            if !included && trace_filtering
              Rails.logger.debug { "[ModelDetector] Excluding #{model.name}: did not match include patterns" }
            end
            included
          end
          log_filter_step('Include patterns', before_count, models.size, trace_filtering)
        end

        # Exclude abstract models and models without valid tables
        before_count = models.size
        models = filter_models_concurrently(models, trace_filtering, options)
        log_filter_step('Abstract/invalid table removal', before_count, models.size, trace_filtering)

        # Exclude tables from configuration
        excluded_tables = RailsLens.config.schema[:exclude_tables]
        before_count = models.size
        models = models.reject do |model|
          begin
            excluded = excluded_tables.include?(model.table_name)
            if excluded && trace_filtering
              Rails.logger.debug do
                "[ModelDetector] Excluding #{model.name}: table '#{model.table_name}' in exclude_tables config"
              end
            end
            excluded
          rescue ActiveRecord::ConnectionNotDefined
            # This can happen in multi-db setups if the connection is not yet established
            # We will assume the model should be kept in this case
            if trace_filtering
              Rails.logger.debug do
                "[ModelDetector] Keeping #{model.name}: connection not defined, assuming keep"
              end
            end
            false
          end
        rescue ActiveRecord::StatementInvalid => e
          if trace_filtering
            Rails.logger.debug do
              "[ModelDetector] Keeping #{model.name}: database error checking exclude_tables - #{e.message}"
            end
          end
          false
        end
        log_filter_step('Configuration exclude_tables', before_count, models.size, trace_filtering)

        if trace_filtering
          Rails.logger.debug do
            "[ModelDetector] Final result: #{models.size} models after all filtering"
          end
        end
        Rails.logger.debug { "[ModelDetector] Final models: #{models.map(&:name).join(', ')}" } if trace_filtering

        models
      end

      def log_filter_step(step_name, before_count, after_count, trace_filtering)
        return unless trace_filtering

        filtered_count = before_count - after_count
        if filtered_count.positive?
          Rails.logger.debug do
            "[ModelDetector] #{step_name}: filtered out #{filtered_count} models (#{before_count} -> #{after_count})"
          end
        else
          Rails.logger.debug { "[ModelDetector] #{step_name}: no models filtered (#{after_count} remain)" }
        end
      end

      def filter_models_concurrently(models, trace_filtering, options = {})
        # Use concurrent futures to check table existence in parallel
        futures = models.map do |model|
          Concurrent::Future.execute do
            should_exclude = false
            reason = nil

            begin
              # Skip abstract models unless explicitly included
              if model.abstract_class? && !options[:include_abstract]
                should_exclude = true
                reason = 'abstract class'
              # For abstract models that are included, skip table checks
              elsif model.abstract_class? && options[:include_abstract]
                reason = 'abstract class (included)'
              # Skip models without configured tables
              elsif !model.table_name
                should_exclude = true
                reason = 'no table name'
              # Skip models whose tables don't exist
              elsif !model.table_exists?
                should_exclude = true
                reason = "table '#{model.table_name}' does not exist"
              # Additional check: Skip models that don't have any columns
              elsif model.columns.empty?
                should_exclude = true
                reason = "table '#{model.table_name}' has no columns"
              else
                reason = "table '#{model.table_name}' exists with #{model.columns.size} columns"
              end
            rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotDefined => e
              should_exclude = true
              reason = "database error checking model - #{e.message}"
            rescue NameError, NoMethodError => e
              should_exclude = true
              reason = "method error checking model - #{e.message}"
            rescue StandardError => e
              # Catch any other errors and exclude the model to prevent ERD corruption
              should_exclude = true
              reason = "unexpected error checking model - #{e.message}"
            end

            if trace_filtering
              action = should_exclude ? 'Excluding' : 'Keeping'
              Rails.logger.debug { "[ModelDetector] #{action} #{model.name}: #{reason}" }
            end

            { model: model, exclude: should_exclude }
          end
        end

        # Wait for all futures to complete and filter results
        results = futures.map(&:value!)
        results.reject { |result| result[:exclude] }.pluck(:model)
      end

      def has_sti_column?(model)
        return false unless model.table_exists?

        sti_column = model.inheritance_column
        model.column_names.include?(sti_column)
      rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotDefined
        false
      end
    end
  end
end
