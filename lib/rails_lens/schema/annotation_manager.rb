# frozen_string_literal: true

module RailsLens
  module Schema
    class AnnotationManager
      attr_reader :model_class

      def initialize(model_class)
        @model_class = model_class
      end

      def annotate_file(file_path = nil, allow_external_files: false)
        file_path ||= model_file_path
        return unless file_path && File.exist?(file_path)

        # Only annotate files within the Rails application (unless explicitly allowed)
        # For engines/gems with dummy apps, check if the file is within the parent directory
        if !allow_external_files && defined?(Rails.root)
          rails_root = Rails.root.to_s
          # Check if this is a dummy app inside a gem/engine
          parent_root = if rails_root.include?('/test/dummy')
                          File.expand_path('../..', rails_root)
                        else
                          rails_root
                        end

          unless file_path.start_with?(rails_root) || file_path.start_with?(parent_root)
            return
          end
        end

        annotation_text = generate_annotation

        # First remove any existing annotations
        content = File.read(file_path)
        content = Annotation.remove(content) if Annotation.extract(content)

        # Try AST-based insertion first
        class_name = model_class.name.split('::').last

        # Use Prism-based insertion
        if FileInsertionHelper.insert_at_class_definition(file_path, class_name, annotation_text)
          true
        else
          # Final fallback to old method
          annotated_content = add_annotation(content, file_path)
          if annotated_content == content
            false
          else
            File.write(file_path, annotated_content)
            true
          end
        end
      end

      def remove_annotations(file_path = nil)
        file_path ||= model_file_path
        return unless file_path && File.exist?(file_path)

        content = File.read(file_path)
        cleaned_content = Annotation.remove(content)

        if cleaned_content == content
          false
        else
          File.write(file_path, cleaned_content)
          true
        end
      end

      def generate_annotation
        pipeline = AnnotationPipeline.new

        # If we have a connection set by annotate_all, use it to process all providers
        if @connection
          results = { schema: nil, sections: [], notes: [] }

          pipeline.instance_variable_get(:@providers).each do |provider|
            next unless provider.applicable?(model_class)

            begin
              result = provider.process(model_class, @connection)

              case provider.type
              when :schema
                results[:schema] = result
              when :section
                results[:sections] << result if result
              when :notes
                results[:notes].concat(Array(result))
              end
            rescue StandardError => e
              warn "Provider #{provider.class} error for #{model_class}: #{e.message}"
            end
          end
        else
          # Fallback: Use the model's connection pool with proper management
          # This path is used when annotating individual models
          warn "Using fallback connection management for #{model_class.name}" if RailsLens.config.verbose

          # Force connection management even in fallback mode
          results = { schema: nil, sections: [], notes: [] }

          model_class.connection_pool.with_connection do |connection|
            pipeline.instance_variable_get(:@providers).each do |provider|
              next unless provider.applicable?(model_class)

              begin
                result = provider.process(model_class, connection)

                case provider.type
                when :schema
                  results[:schema] = result
                when :section
                  results[:sections] << result if result
                when :notes
                  results[:notes].concat(Array(result))
                end
              rescue StandardError => e
                warn "Provider #{provider.class} error for #{model_class}: #{e.message}"
              end
            end
          end
        end

        annotation = Annotation.new

        # Add schema content
        annotation.add_lines(results[:schema].split("\n")) if results[:schema]

        # Add sections
        results[:sections].each do |section|
          next unless section && section[:content]

          annotation.add_line('')
          # The provider can optionally provide a title
          annotation.add_line(section[:title]) if section[:title]
          annotation.add_lines(section[:content].split("\n"))
        end

        # Add notes as TOML array (already in compact format from analyzers)
        if results[:notes].any?
          annotation.add_line('')
          annotation.add_line("notes = [#{results[:notes].uniq.map { |n| "\"#{n}\"" }.join(', ')}]")
        end

        annotation.to_s
      end

      def self.annotate_all(options = {})
        results = { annotated: [], skipped: [], failed: [] }

        # Iterate through all model sources
        ModelSourceLoader.load_sources.each do |source|
          puts "Annotating #{source.source_name} models..." if options[:verbose]
          source_results = annotate_source(source, options)
          merge_results(results, source_results)
        end

        results
      end

      # Annotate models from a specific source
      def self.annotate_source(source, options = {})
        results = { annotated: [], skipped: [], failed: [] }

        begin
          models = source.models(options)
          puts "  Found #{models.size} #{source.source_name} models" if options[:verbose]

          models.each do |model|
            result = source.annotate_model(model, options)
            case result[:status]
            when :annotated
              results[:annotated] << result[:model]
            when :skipped
              results[:skipped] << result[:model]
            when :failed
              results[:failed] << { model: result[:model], error: result[:message] }
            end
          end
        rescue StandardError => e
          puts "  Error processing #{source.source_name} source: #{e.message}" if options[:verbose]
        end

        results
      end

      # Merge source results into main results
      def self.merge_results(main, source)
        main[:annotated].concat(source[:annotated] || [])
        main[:skipped].concat(source[:skipped] || [])
        main[:failed].concat(source[:failed] || [])
      end

      # Original ActiveRecord-specific annotation logic (used by ActiveRecordSource)
      def self.annotate_active_record_models(options = {})
        # Convert models option to include option for ModelDetector
        if options[:models]
          options[:include] = options[:models]
        end

        models = ModelDetector.detect_models(options)
        puts "Detected #{models.size} models for annotation" if options[:verbose]

        # Filter abstract classes based on options
        if options[:include_abstract]
          # Include all models
        elsif options[:abstract_only]
          models = models.select(&:abstract_class?)
        else
          # Default: exclude abstract classes
          models = models.reject(&:abstract_class?)
        end

        results = { annotated: [], skipped: [], failed: [] }

        # Group models by their connection pool to process each database separately
        models_by_connection_pool = models.group_by do |model|
          pool = model.connection_pool
          pool
        rescue StandardError => e
          puts "Model #{model.name} -> NO POOL (#{e.message})" if options[:verbose]
          nil # Models without connection pools will use primary pool
        end

        # Force models without connection pools to use the primary connection pool
        if models_by_connection_pool[nil]&.any?
          begin
            primary_pool = ApplicationRecord.connection_pool
            models_by_connection_pool[primary_pool] ||= []
            models_by_connection_pool[primary_pool].concat(models_by_connection_pool[nil])
            models_by_connection_pool.delete(nil)
          rescue StandardError => e
            puts "Failed to assign to primary pool: #{e.message}" if options[:verbose]
          end
        end

        models_by_connection_pool.each do |connection_pool, pool_models|
          if connection_pool
            # Process all models for this database using a single connection
            connection_pool.with_connection do |connection|
              pool_models.each do |model|
                process_model_with_connection(model, connection, results, options)
              end
            end
          else
            # This should not happen anymore since we assign orphaned models to primary pool
            # Use primary connection pool as fallback to avoid creating new connections
            begin
              primary_pool = ApplicationRecord.connection_pool
              primary_pool.with_connection do |connection|
                pool_models.each do |model|
                  process_model_with_connection(model, connection, results, options)
                end
              end
            rescue StandardError => e
              # Last resort: process without connection management (will create multiple connections)
              pool_models.each do |model|
                process_model_with_connection(model, nil, results, options)
              end
            end
          end
        end

        results
      end

      def self.process_model_with_connection(model, connection, results, options)
        # Ensure model is actually a class, not a hash or other object
        unless model.is_a?(Class)
          results[:failed] << { model: model.inspect, error: "Expected Class, got #{model.class}" }
          return
        end

        # Skip models without tables or with missing tables (but not abstract classes)
        unless model.abstract_class? || model.table_exists?
          results[:skipped] << model.name
          return
        end

        manager = new(model)

        # Set the connection in the manager if provided
        manager.instance_variable_set(:@connection, connection) if connection

        # Determine file path based on options
        file_path = if options[:models_path]
                      File.join(options[:models_path], "#{model.name.underscore}.rb")
                    else
                      nil # Use default model_file_path
                    end

        # Allow external files when models_path is provided (for testing)
        allow_external = options[:models_path].present?

        if manager.annotate_file(file_path, allow_external_files: allow_external)
          results[:annotated] << model.name
        else
          results[:skipped] << model.name
        end
      rescue ActiveRecord::StatementInvalid
        # Handle database-related errors (missing tables, schemas, etc.)
        results[:skipped] << model.name
      rescue StandardError => e
        model_name = if model.is_a?(Class) && model.respond_to?(:name)
                       model.name
                     else
                       model.inspect
                     end
        results[:failed] << { model: model_name, error: e.message }
      end

      def self.remove_all(options = {})
        results = { removed: [], skipped: [], failed: [] }

        # Iterate through all model sources
        ModelSourceLoader.load_sources.each do |source|
          puts "Removing annotations from #{source.source_name} models..." if options[:verbose]
          source_results = remove_source(source, options)
          merge_remove_results(results, source_results)
        end

        results
      end

      # Remove annotations from a specific source
      def self.remove_source(source, options = {})
        results = { removed: [], skipped: [], failed: [] }

        begin
          models = source.models(options.merge(include_abstract: true))
          puts "  Found #{models.size} #{source.source_name} models" if options[:verbose]

          models.each do |model|
            result = source.remove_annotation(model)
            case result[:status]
            when :removed
              results[:removed] << result[:model]
            when :skipped
              results[:skipped] << result[:model]
            when :failed
              results[:failed] << { model: result[:model], error: result[:message] }
            end
          end
        rescue StandardError => e
          puts "  Error removing from #{source.source_name} source: #{e.message}" if options[:verbose]
        end

        results
      end

      # Merge removal results into main results
      def self.merge_remove_results(main, source)
        main[:removed].concat(source[:removed] || [])
        main[:skipped].concat(source[:skipped] || [])
        main[:failed].concat(source[:failed] || [])
      end

      # Original filesystem-based removal (kept for backwards compatibility)
      def self.remove_all_by_filesystem(options = {})
        base_path = options[:models_path] || default_models_path
        results = { removed: [], skipped: [], failed: [] }
        pattern = File.join(base_path, '**', '*.rb')
        files = Dir.glob(pattern)

        files.each do |file_path|
          content = File.read(file_path)
          next unless Annotation.extract(content)

          cleaned = Annotation.remove(content)
          if cleaned == content
            results[:skipped] << File.basename(file_path, '.rb').camelize
          else
            File.write(file_path, cleaned)
            model_name = File.basename(file_path, '.rb').camelize
            results[:removed] << model_name
          end
        rescue StandardError => e
          results[:failed] << { model: File.basename(file_path, '.rb').camelize, error: e.message }
        end

        results
      end

      def self.default_models_path
        return Rails.root.join('app/models') if defined?(Rails.root)

        File.join(Dir.pwd, 'app', 'models')
      end

      private

      def add_annotation(content, _file_path = nil)
        annotation_text = generate_annotation

        # First check if annotation already exists and remove it
        existing = Annotation.extract(content)
        content = Annotation.remove(content) if existing

        # Use the file insertion helper to insert after frozen_string_literal
        FileInsertionHelper.insert_after_frozen_string_literal(content, annotation_text)
      end

      def model_file_path
        # First try const_source_location as it's more reliable for finding model files
        const_source_location = Object.const_source_location(model_class.name)
        return const_source_location.first if const_source_location

        # Fallback to instance method source location (though this often points to ActiveRecord)
        model_class.instance_method(:initialize).source_location.first
      rescue StandardError
        # As a last resort, try to construct the path from Rails conventions
        if defined?(Rails.root) && model_class.name
          model_path = Rails.root.join('app', 'models', "#{model_class.name.underscore}.rb").to_s
          model_path if File.exist?(model_path)
        end
      end
    end
  end
end
