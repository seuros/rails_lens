# frozen_string_literal: true

module RailsLens
  module Mailer
    # Handles adding mailer annotations to mailer files
    class Annotator
      def initialize(dry_run: false)
        @dry_run = dry_run
        @mailers = RailsLens::Mailer::Extractor.call
        @changed_files = []
      end

      # Annotate all mailer files with mailer information
      #
      # @param pattern [String] Glob pattern for mailer files
      # @param exclusion [String] Glob pattern for files to exclude
      # @return [Array<String>] List of changed files
      def annotate_all(pattern: '**/*_mailer.rb', exclusion: 'vendor/**/*_mailer.rb')
        # Simply annotate all mailer files we found via their source locations
        source_paths_map.each do |source_path, methods|
          # Skip vendor files or files matching exclusion pattern
          next if exclusion && source_path.include?('vendor/')

          annotate_file(path: source_path, methods: methods) if File.exist?(source_path)
        end

        @changed_files
      end

      # Remove mailer annotations from all mailer files
      #
      # @param pattern [String] Glob pattern for mailer files
      # @param exclusion [String] Glob pattern for files to exclude
      # @return [Array<String>] List of changed files
      def remove_all(pattern: '**/*_mailer.rb', exclusion: 'vendor/**/*_mailer.rb')
        # Remove annotations from all mailer files we found via their source locations
        source_paths_map.each_key do |source_path|
          # Skip vendor files or files matching exclusion pattern
          next if exclusion && source_path.include?('vendor/')

          remove_annotations_from_file(source_path) if File.exist?(source_path)
        end

        @changed_files
      end

      private

      # Map source paths to their respective mailer methods
      #
      # @return [Hash] Source paths mapped to their methods
      def source_paths_map
        map = {}

        @mailers.each_value do |methods|
          methods.each do |method_name, method_info|
            source_path = method_info[:source_path]
            next unless source_path

            map[source_path] ||= {}
            map[source_path][method_name] = method_info
          end
        end

        map
      end

      # Annotate a single mailer file
      #
      # @param path [String] Path to mailer file
      # @param methods [Hash] Method data for the mailer
      # @return [void]
      def annotate_file(path:, methods:)
        # First, remove any existing annotations
        remove_annotations_from_file(path)

        # Use our precise parser to find all mailer classes
        parser_result = RailsLens::Parsers::PrismParser.parse_file(path)
        mailer_classes = parser_result.classes.select { |cls| cls.name.end_with?('Mailer') }

        # Collect all annotations for this file first (to handle multiple classes properly)
        annotations_to_insert = []

        # Annotate each mailer class individually
        mailer_classes.each do |mailer_class|
          # Find methods for this specific mailer class from the original @mailers data
          class_methods = {}

          # Look through all mailer classes to find methods for this specific class
          @mailers.each do |mailer_class_name, mailer_methods|
            next unless mailer_class_name == mailer_class.name || mailer_class_name == mailer_class.full_name

            # Filter methods that are in this specific file
            file_methods = mailer_methods.select do |_method_name, method_info|
              method_info[:source_path] == path
            end
            class_methods.merge!(file_methods)
          end

          next if class_methods.empty?

          # Get class-level information from first method
          first_method = class_methods.values.first
          next unless first_method

          # Build class annotation
          annotation_lines = []
          annotation_lines << '# <rails-lens:mailers:begin>'

          # Add delivery method
          annotation_lines << "# DELIVERY_METHOD: #{first_method[:delivery_method]}" if first_method[:delivery_method]

          # Add locales
          annotation_lines << "# LOCALES: #{first_method[:locales].join(', ')}" if first_method[:locales]&.any?

          # Add defaults
          if first_method[:defaults]&.any?
            defaults_strings = first_method[:defaults].map { |k, v| "#{k}: #{v}" }
            annotation_lines << "# DEFAULTS: #{defaults_strings.join(', ')}"
          end

          annotation_lines << '# <rails-lens:mailers:end>'
          annotation_block = annotation_lines.join("\n")

          # Store annotation for batch processing
          annotations_to_insert << {
            class_name: mailer_class.name,
            line_number: mailer_class.line_number,
            annotation: annotation_block
          }
        end

        # Insert all annotations in reverse line order (bottom to top) to preserve line numbers
        annotations_to_insert.sort_by { |ann| -ann[:line_number] }.each do |annotation_info|
          success = RailsLens::FileInsertionHelper.insert_at_class_definition(
            path,
            annotation_info[:class_name],
            annotation_info[:annotation]
          )

          warn "Could not annotate #{annotation_info[:class_name]} in #{path}" unless success
        end

        # Add file to changed files list if any annotations were inserted
        return unless annotations_to_insert.any?

        @changed_files << path
      end

      # Remove annotations from a single file
      #
      # @param path [String] Path to mailer file
      # @return [void]
      def remove_annotations_from_file(path)
        content = File.read(path)
        original_content = content.dup

        # Remove rails-lens mailer annotations
        content.gsub!(/^.*<rails-lens:mailers:begin>.*$\n/, '')
        content.gsub!(/^.*<rails-lens:mailers:end>.*$\n/, '')
        content.gsub!(/^\s*#\s*== Mailer Information.*$\n/, '')
        content.gsub!(/^\s*#\s*Templates:.*$\n/, '')
        content.gsub!(/^\s*#\s*Formats:.*$\n/, '')
        content.gsub!(/^\s*#\s*FORMATS:.*$\n/, '')
        content.gsub!(/^\s*#\s*Delivery Method:.*$\n/, '')
        content.gsub!(/^\s*#\s*DELIVERY_METHOD:.*$\n/, '')
        content.gsub!(/^\s*#\s*Parameters:.*$\n/, '')
        content.gsub!(/^\s*#\s*Locales:.*$\n/, '')
        content.gsub!(/^\s*#\s*LOCALES:.*$\n/, '')
        content.gsub!(/^\s*#\s*Defaults:.*$\n/, '')
        content.gsub!(/^\s*#\s*DEFAULTS:.*$\n/, '')

        return unless content != original_content

        write_content_to_file(path: path, content: content)
      end

      # Extract formats from template filenames
      #
      # @param templates [Array<String>] Template filenames
      # @return [Array<String>] Extracted formats
      def extract_formats_from_templates(templates)
        formats = []

        templates.each do |template|
          # Extract format from filename like "method_name.html.erb" or "method_name.text.erb"
          parts = template.split('.')
          if parts.length >= 2
            format = parts[-2] # Get the format part (html, text, etc.)
            formats << format unless formats.include?(format)
          end
        end

        formats.sort
      end

      # Write content to file
      #
      # @param path [String] File path
      # @param content [String] File content
      # @return [void]
      def write_content_to_file(path:, content:)
        return if @dry_run

        File.write(path, content)
        @changed_files << path
      end

      # Check if a mailer file exists and contains mailer classes
      #
      # @param path [String] File path
      # @return [Boolean] Whether file exists and contains mailer classes
      def mailer_file_exists?(path)
        return false unless File.exist?(path)

        begin
          parser_result = RailsLens::Parsers::PrismParser.parse_file(path)
          parser_result.classes.any? { |cls| cls.name.end_with?('Mailer') }
        rescue RailsLens::ParseError, Errno::ENOENT, IOError
          # Fallback to filename-based detection
          File.basename(path).end_with?('_mailer.rb')
        end
      end
    end
  end
end
