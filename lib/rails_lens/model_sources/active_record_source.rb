# frozen_string_literal: true

module RailsLens
  module ModelSources
    # Built-in model source for ActiveRecord models
    class ActiveRecordSource < ModelSource
      class << self
        def models(options = {})
          # Convert models option to include option for ModelDetector
          opts = options.dup
          opts[:include] = opts.delete(:models) if opts[:models]

          models = ModelDetector.detect_models(opts)

          # Filter abstract classes based on options
          if opts[:include_abstract]
            # Include all models
          elsif opts[:abstract_only]
            models = models.select(&:abstract_class?)
          else
            # Default: exclude abstract classes
            models = models.reject(&:abstract_class?)
          end

          models
        end

        def file_patterns
          ['app/models/**/*.rb']
        end

        def annotate_model(model, options = {})
          # Use the optimized connection-pooled annotation
          results = { annotated: [], skipped: [], failed: [] }

          # Group this single model by connection pool for consistency
          begin
            pool = model.connection_pool
            pool.with_connection do |connection|
              Schema::AnnotationManager.process_model_with_connection(model, connection, results, options)
            end
          rescue StandardError
            # Fallback without connection management
            Schema::AnnotationManager.process_model_with_connection(model, nil, results, options)
          end

          if results[:annotated].include?(model.name)
            { status: :annotated, model: model.name, file: model_file_path(model) }
          elsif results[:failed].any? { |f| f[:model] == model.name }
            failure = results[:failed].find { |f| f[:model] == model.name }
            { status: :failed, model: model.name, message: failure[:error] }
          else
            { status: :skipped, model: model.name }
          end
        end

        def remove_annotation(model)
          manager = Schema::AnnotationManager.new(model)
          if manager.remove_annotations
            { status: :removed, model: model.name, file: model_file_path(model) }
          else
            { status: :skipped, model: model.name }
          end
        rescue StandardError => e
          { status: :failed, model: model.name, message: e.message }
        end

        def source_name
          'ActiveRecord'
        end

        private

        def model_file_path(model)
          return nil unless model.name

          const_source_location = Object.const_source_location(model.name)
          return const_source_location.first if const_source_location

          if defined?(Rails.root)
            Rails.root.join('app', 'models', "#{model.name.underscore}.rb").to_s
          end
        rescue StandardError
          nil
        end
      end
    end
  end
end
