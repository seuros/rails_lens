# frozen_string_literal: true

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
          SELECT 1 FROM information_schema.views
          WHERE table_name = '#{connection.quote_string(table_name)}'
          UNION ALL
          SELECT 1 FROM pg_matviews
          WHERE matviewname = '#{connection.quote_string(table_name)}'
          LIMIT 1
        SQL
        result.rows.any?
      end

      def check_mysql_view(connection, table_name)
        result = connection.exec_query(<<~SQL.squish, 'Check MySQL View')
          SELECT 1 FROM information_schema.views
          WHERE table_name = '#{connection.quote_string(table_name)}'
          AND table_schema = DATABASE()
          LIMIT 1
        SQL
        result.rows.any?
      end

      def check_sqlite_view(connection, table_name)
        result = connection.exec_query(<<~SQL.squish, 'Check SQLite View')
          SELECT 1 FROM sqlite_master
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
        RailsLens.logger.debug { "[ModelDetector] Starting with #{original_count} models" } if trace_filtering

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
              RailsLens.logger.debug do
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
              RailsLens.logger.debug do
                "[ModelDetector] Including #{model.name}: matched include pattern"
              end
            end
            if !included && trace_filtering
              RailsLens.logger.debug { "[ModelDetector] Excluding #{model.name}: did not match include patterns" }
            end
            included
          end
          log_filter_step('Include patterns', before_count, models.size, trace_filtering)
        end

        # Exclude abstract models and models without valid tables
        before_count = models.size

        # Use connection management during model filtering to prevent connection exhaustion
        models = filter_models_with_connection_management(models, trace_filtering, options)

        log_filter_step('Abstract/invalid table removal', before_count, models.size, trace_filtering)

        # Exclude tables from configuration
        excluded_tables = RailsLens.excluded_tables
        before_count = models.size
        models = models.reject do |model|
          begin
            excluded = excluded_tables.include?(model.table_name)
            if excluded && trace_filtering
              RailsLens.logger.debug do
                "[ModelDetector] Excluding #{model.name}: table '#{model.table_name}' in exclude_tables config"
              end
            end
            excluded
          rescue ActiveRecord::ConnectionNotDefined
            # This can happen in multi-db setups if the connection is not yet established
            # We will assume the model should be kept in this case
            if trace_filtering
              RailsLens.logger.debug do
                "[ModelDetector] Keeping #{model.name}: connection not defined, assuming keep"
              end
            end
            false
          end
        rescue ActiveRecord::StatementInvalid => e
          if trace_filtering
            RailsLens.logger.debug do
              "[ModelDetector] Keeping #{model.name}: database error checking exclude_tables - #{e.message}"
            end
          end
          false
        end
        log_filter_step('Configuration exclude_tables', before_count, models.size, trace_filtering)

        if trace_filtering
          RailsLens.logger.debug do
            "[ModelDetector] Final result: #{models.size} models after all filtering"
          end
        end
        RailsLens.logger.debug { "[ModelDetector] Final models: #{models.map(&:name).join(', ')}" } if trace_filtering

        models
      end

      def log_filter_step(step_name, before_count, after_count, trace_filtering)
        return unless trace_filtering

        filtered_count = before_count - after_count
        if filtered_count.positive?
          RailsLens.logger.debug do
            "[ModelDetector] #{step_name}: filtered out #{filtered_count} models (#{before_count} -> #{after_count})"
          end
        else
          RailsLens.logger.debug { "[ModelDetector] #{step_name}: no models filtered (#{after_count} remain)" }
        end
      end

      def filter_models_concurrently(models, trace_filtering, options = {})
        puts "ModelDetector: Sequential filtering #{models.size} models..." if options[:verbose]
        # Process models sequentially to prevent concurrent database connections
        results = models.map do |model|
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
            RailsLens.logger.debug { "[ModelDetector] #{action} #{model.name}: #{reason}" }
          end

          { model: model, exclude: should_exclude }
        end

        # Filter out excluded models
        results.reject { |result| result[:exclude] }.pluck(:model)
      end

      def filter_models_with_connection_management(models, trace_filtering, options = {})
        # Group models by connection pool first
        models_by_pool = models.group_by do |model|
          model.connection_pool
        rescue StandardError
          nil
        end

        # Assign orphaned models to primary pool
        if models_by_pool[nil]&.any?
          begin
            primary_pool = ApplicationRecord.connection_pool
            models_by_pool[primary_pool] ||= []
            models_by_pool[primary_pool].concat(models_by_pool[nil])
            models_by_pool.delete(nil)
          rescue StandardError
            # Keep orphaned models for individual processing
          end
        end

        all_pools = models_by_pool.keys.compact
        valid_models = []

        models_by_pool.each do |pool, pool_models|
          if pool
            # Disconnect other pools before processing this one
            all_pools.each do |p|
              next if p == pool

              begin
                p.disconnect! if p.connected?
              rescue StandardError
                # Ignore disconnect errors
              end
            end

            # Process models with managed connection
            pool.with_connection do |connection|
              pool_models.each do |model|
                result = filter_single_model(model, connection, trace_filtering, options)
                valid_models << model unless result[:exclude]
              end
            end
          else
            # Fallback for models without pools
            pool_models.each do |model|
              result = filter_single_model(model, nil, trace_filtering, options)
              valid_models << model unless result[:exclude]
            end
          end
        end

        valid_models
      end

      def filter_single_model(model, connection, trace_filtering, options)
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
          # Skip models whose tables don't exist (use connection if available)
          elsif connection ? !table_exists_with_connection?(model, connection) : !model.table_exists?
            should_exclude = true
            reason = "table '#{model.table_name}' does not exist"
          # Additional check: Skip models that don't have any columns
          elsif connection ? columns_empty_with_connection?(model, connection) : model.columns.empty?
            should_exclude = true
            reason = "table '#{model.table_name}' has no columns"
          else
            column_count = connection ? get_column_count_with_connection(model, connection) : model.columns.size
            reason = "table '#{model.table_name}' exists with #{column_count} columns"
          end
        rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotDefined => e
          should_exclude = true
          reason = "database error checking model - #{e.message}"
        rescue NameError, NoMethodError => e
          should_exclude = true
          reason = "method error checking model - #{e.message}"
        rescue StandardError => e
          # Catch any other errors and exclude the model to prevent corruption
          should_exclude = true
          reason = "unexpected error checking model - #{e.message}"
        end

        if trace_filtering
          action = should_exclude ? 'Excluding' : 'Keeping'
          RailsLens.logger.debug { "[ModelDetector] #{action} #{model.name}: #{reason}" }
        end

        { model: model, exclude: should_exclude }
      end

      def table_exists_with_connection?(model, connection)
        table_name = model.table_name

        # Handle schema-qualified table names for PostgreSQL (e.g., 'audit.audit_logs')
        if connection.adapter_name == 'PostgreSQL' && table_name.include?('.')
          with_schema_in_search_path(connection, table_name) do |unqualified_name|
            connection.table_exists?(unqualified_name) || connection.views.include?(unqualified_name)
          end
        else
          # Check both tables and views
          return true if connection.table_exists?(table_name)
          return true if connection.views.include?(table_name)

          # Fallback for SQLite: direct sqlite_master query for views
          if connection.adapter_name.downcase.include?('sqlite')
            check_sqlite_view(connection, table_name)
          else
            false
          end
        end
      rescue StandardError
        false
      end

      def columns_empty_with_connection?(model, connection)
        table_name = model.table_name

        if connection.adapter_name == 'PostgreSQL' && table_name.include?('.')
          with_schema_in_search_path(connection, table_name) do |unqualified_name|
            connection.columns(unqualified_name).empty?
          end
        else
          connection.columns(table_name).empty?
        end
      rescue StandardError
        true
      end

      def get_column_count_with_connection(model, connection)
        table_name = model.table_name

        if connection.adapter_name == 'PostgreSQL' && table_name.include?('.')
          with_schema_in_search_path(connection, table_name) do |unqualified_name|
            connection.columns(unqualified_name).size
          end
        else
          connection.columns(table_name).size
        end
      rescue StandardError
        0
      end

      # Helper to execute block with schema in PostgreSQL search_path
      def with_schema_in_search_path(connection, qualified_table_name)
        schema_name, unqualified_name = qualified_table_name.split('.', 2)
        original_search_path = connection.schema_search_path
        begin
          connection.schema_search_path = "#{schema_name}, #{original_search_path}"
          yield unqualified_name
        ensure
          connection.schema_search_path = original_search_path
        end
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
