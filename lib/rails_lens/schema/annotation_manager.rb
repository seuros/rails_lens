# frozen_string_literal: true

require_relative '../file_insertion_helper'

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
        if !allow_external_files && defined?(Rails.root) && !file_path.start_with?(Rails.root.to_s)
          return
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
        results = pipeline.process(model_class)

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

        # Add notes
        if results[:notes].any?
          annotation.add_line('')
          annotation.add_line('== Notes')
          results[:notes].uniq.each do |note|
            annotation.add_line("- #{note}")
          end
        end

        annotation.to_s
      end

      def self.annotate_all(options = {})
        models = ModelDetector.detect_models(options)

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

        models.each do |model|
          # Ensure model is actually a class, not a hash or other object
          unless model.is_a?(Class)
            results[:failed] << { model: model.inspect, error: "Expected Class, got #{model.class}" }
            next
          end

          # Skip models without tables or with missing tables (but not abstract classes)
          unless model.abstract_class? || model.table_exists?
            results[:skipped] << model.name
            warn "Skipping #{model.name} - table does not exist" if options[:verbose]
            next
          end

          manager = new(model)

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
        rescue ActiveRecord::StatementInvalid => e
          # Handle database-related errors (missing tables, schemas, etc.)
          results[:skipped] << model.name
          warn "Skipping #{model.name} - database error: #{e.message}" if options[:verbose]
        rescue StandardError => e
          model_name = if model.is_a?(Class) && model.respond_to?(:name)
                         model.name
                       else
                         model.inspect
                       end
          results[:failed] << { model: model_name, error: e.message }
        end

        results
      end

      def self.remove_all(options = {})
        models = ModelDetector.detect_models(options)
        results = { removed: [], skipped: [], failed: [] }

        models.each do |model|
          manager = new(model)
          if manager.remove_annotations
            results[:removed] << model.name
          else
            results[:skipped] << model.name
          end
        rescue StandardError => e
          results[:failed] << { model: model.name, error: e.message }
        end

        results
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
