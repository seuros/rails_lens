# frozen_string_literal: true

module RailsLens
  module Schema
    # Annotates abstract base classes (ApplicationRecord, etc.) with database-level objects
    # like functions, sequences, types, etc.
    class DatabaseAnnotator
      attr_reader :base_class

      def initialize(base_class)
        @base_class = base_class
      end

      def annotate_file(file_path = nil)
        file_path ||= model_file_path
        return unless file_path && File.exist?(file_path)

        annotation_text = generate_annotation
        return if annotation_text.empty?

        # Remove existing annotations
        content = File.read(file_path)
        Annotation.remove(content) if Annotation.extract(content)

        # Use Prism-based insertion
        class_name = base_class.name.split('::').last
        if FileInsertionHelper.insert_at_class_definition(file_path, class_name, annotation_text)
          true
        else
          false
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
        annotation = Annotation.new

        # Detect adapter
        adapter_name = base_class.connection.adapter_name

        case adapter_name
        when /PostgreSQL/i
          add_postgresql_functions(annotation)
        when /MySQL/i
          add_mysql_functions(annotation)
        when /SQLite/i
          # SQLite doesn't have stored functions
        end

        annotation.to_s
      end

      # Class methods for batch operations
      def self.annotate_all(options = {})
        results = { annotated: [], skipped: [], failed: [] }

        abstract_classes = detect_abstract_base_classes

        abstract_classes.each do |klass|
          annotator = new(klass)

          begin
            if annotator.annotate_file
              results[:annotated] << klass.name
            else
              results[:skipped] << klass.name
            end
          rescue StandardError => e
            results[:failed] << { model: klass.name, error: e.message }
          end
        end

        results
      end

      def self.remove_all(options = {})
        results = { removed: [], skipped: [], failed: [] }

        begin
          abstract_classes = detect_abstract_base_classes
        rescue StandardError => e
          RailsLens.logger.error { "Failed to detect abstract base classes: #{e.message}" }
          return results
        end

        abstract_classes.each do |klass|
          annotator = new(klass)
          if annotator.remove_annotations
            results[:removed] << klass.name
          else
            results[:skipped] << klass.name
          end
        rescue StandardError => e
          results[:failed] << { model: klass.name, error: e.message }
        end

        results
      end

      def self.detect_abstract_base_classes
        return [] unless defined?(Rails)

        classes = []

        # Load all models
        Rails.application.eager_load!

        # Find abstract base classes that inherit from ActiveRecord::Base
        ActiveRecord::Base.descendants.each do |klass|
          next unless klass.abstract_class?
          next if klass == ActiveRecord::Base

          classes << klass
        end

        classes
      end

      private_class_method :detect_abstract_base_classes

      private

      def add_postgresql_functions(annotation)
        return unless RailsLens.config.schema[:format_options][:show_functions]

        require_relative 'adapters/postgresql'
        functions = Adapters::Postgresql.fetch_functions(base_class.connection)
        add_functions_annotation(annotation, functions)
      end

      def add_mysql_functions(annotation)
        return unless RailsLens.config.schema[:format_options][:show_functions]

        require_relative 'adapters/mysql'
        functions = Adapters::Mysql.fetch_functions(base_class.connection)
        add_functions_annotation(annotation, functions)
      end

      def add_functions_annotation(annotation, functions)
        return if functions.empty?

        annotation.add_line('== Database Functions')
        annotation.add_line('')
        annotation.add_line('functions = [')

        functions.each_with_index do |func, index|
          line = '  { '
          attrs = []
          attrs << "name = \"#{escape_toml_string(func[:name])}\""
          attrs << "schema = \"#{escape_toml_string(func[:schema])}\""
          attrs << "language = \"#{escape_toml_string(func[:language])}\""
          attrs << "return_type = \"#{escape_toml_string(func[:return_type])}\""
          attrs << "description = \"#{escape_toml_string(func[:description])}\"" if func[:description]
          line += attrs.join(', ')
          line += ' }'
          line += ',' if index < functions.length - 1
          annotation.add_line(line)
        end

        annotation.add_line(']')
      end

      def escape_toml_string(str)
        return '' unless str

        str.to_s.gsub('\\', '\\\\').gsub('"', '\\"')
      end

      def model_file_path
        return nil unless base_class.name

        # Convert class name to file path (e.g., ApplicationRecord -> application_record.rb)
        file_name = "#{base_class.name.underscore}.rb"

        # Look in app/models
        path = Rails.root.join('app', 'models', file_name) if defined?(Rails.root)
        path if path && File.exist?(path)
      end
    end
  end
end
