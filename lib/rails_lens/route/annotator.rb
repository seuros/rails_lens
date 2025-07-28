# frozen_string_literal: true

module RailsLens
  module Route
    # Handles adding route annotations to controller files
    class Annotator
      def initialize(dry_run: false)
        @dry_run = dry_run
        @routes = RailsLens::Route::Extractor.call
        @changed_files = []
      end

      # Annotate all controller files with route information
      #
      # @param pattern [String] Glob pattern for controller files
      # @param exclusion [String] Glob pattern for files to exclude
      # @return [Array<String>] List of changed files
      def annotate_all(pattern: '**/*_controller.rb', exclusion: 'vendor/**/*_controller.rb')
        controller_paths = Rails.root.glob(pattern)
                                .reject { |path| Rails.root.glob(exclusion).include?(path) }

        source_paths_map.each do |source_path, actions|
          # Use exact path matching or find controller files by parsing
          if controller_paths.include?(source_path) || controller_file_exists?(source_path)
            annotate_file(path: source_path, actions: actions)
          end
        end

        @changed_files
      end

      # Remove route annotations from all controller files
      #
      # @param pattern [String] Glob pattern for controller files
      # @param exclusion [String] Glob pattern for files to exclude
      # @return [Array<String>] List of changed files
      def remove_all(pattern: '**/*_controller.rb', exclusion: 'vendor/**/*_controller.rb')
        controller_paths = Rails.root.glob(pattern)
                                .reject { |path| Rails.root.glob(exclusion).include?(path) }

        # Also include controller files from source paths
        all_controller_paths = (controller_paths + source_paths_map.keys).uniq
        all_controller_paths.select! { |path| controller_file_exists?(path) }

        all_controller_paths.each do |path|
          remove_annotations_from_file(path)
        end

        @changed_files
      end

      private

      # Map source paths to their respective routes
      #
      # @return [Hash] Source paths mapped to their routes
      def source_paths_map
        map = {}

        @routes.each_value do |actions|
          actions.each do |action, data|
            data.each do |datum|
              map[datum[:source_path]] ||= {}
              map[datum[:source_path]][action] ||= []
              map[datum[:source_path]][action].push(datum)
            end
          end
        end

        map
      end

      # Annotate a single controller file
      #
      # @param path [String] Path to controller file
      # @param actions [Hash] Action data for the controller
      # @return [void]
      def annotate_file(path:, actions:)
        parsed_file = RailsLens::Route::Parser.call(path: path, actions: actions.keys)

        parsed_file[:groups].each_cons(2) do |prev, curr|
          clean_group(prev)
          next unless curr[:type] == :action

          route_data = actions[curr[:action]]
          next unless route_data&.any?

          annotate_group(group: curr, route_data: route_data)
        end

        write_to_file(path: path, parsed_file: parsed_file)
      end

      # Remove annotations from a single file
      #
      # @param path [String] Path to controller file
      # @return [void]
      def remove_annotations_from_file(path)
        content = File.read(path)
        original_content = content.dup

        # Remove rails-lens route annotations
        content.gsub!(/^.*<rails-lens:routes:begin>.*$\n/, '')
        content.gsub!(/^.*<rails-lens:routes:end>.*$\n/, '')
        content.gsub!(/^\s*#\s*@route.*$\n/, '')
        content.gsub!(/^\s*#\s*ROUTE:.*$\n/, '')

        return unless content != original_content

        write_content_to_file(path: path, content: content)
      end

      # Clean existing route annotations from a comment group
      #
      # @param group [Hash] Parsed group from parser
      # @return [void]
      def clean_group(group)
        return unless group[:type] == :comment

        # Remove existing route annotations
        group[:body] = group[:body].gsub(/^\s*#\s*@route.*$\n/, '')
        group[:body] = group[:body].gsub(/^\s*#\s*ROUTE:.*$\n/, '')
        group[:body] = group[:body].gsub(/^.*<rails-lens:routes:begin>.*$\n/, '')
        group[:body] = group[:body].gsub(/^.*<rails-lens:routes:end>.*$\n/, '')
      end

      # Add route annotations to a group
      #
      # @param group [Hash] Parsed group from parser
      # @param route_data [Array<Hash>] Route data for the action
      # @return [void]
      def annotate_group(group:, route_data:)
        whitespace = /^(\s*).*$/.match(group[:body])[1]

        # Build annotation block
        annotation_lines = []
        annotation_lines << "#{whitespace}# <rails-lens:routes:begin>"

        # Group routes by path only (not by name)
        # This allows different named routes with same path to be merged
        grouped_routes = {}
        route_data.each do |datum|
          key = datum[:path]
          grouped_routes[key] ||= {
            path: datum[:path],
            name: datum[:name],
            verbs: [],
            defaults: datum[:defaults]
          }

          # If this path already has a different name, keep routes separate
          if grouped_routes[key][:name] == datum[:name]
            grouped_routes[key][:verbs] << datum[:verb]
          else
            # Create a unique key for this different route
            unique_key = "#{datum[:path]}__#{datum[:name]}"
            grouped_routes[unique_key] = {
              path: datum[:path],
              name: datum[:name],
              verbs: [datum[:verb]],
              defaults: datum[:defaults]
            }
          end
        end

        # Add grouped annotations
        grouped_routes.values.reverse_each do |route|
          annotation_lines << "#{whitespace}# #{format_route_annotation_structured(**route)}"
        end

        annotation_lines << "#{whitespace}# <rails-lens:routes:end>"

        # Add to group
        annotation_block = "#{annotation_lines.join("\n")}\n"
        group[:body] = annotation_block + group[:body]
      end

      # Format a single route annotation
      #
      # @param verb [String] HTTP verb
      # @param path [String] Route path
      # @param name [String] Route name
      # @param defaults [Hash] Default parameters
      # @param source_path [String] Controller file path
      # @return [String] Formatted annotation
      def format_route_annotation(verb:, path:, name:, defaults:, source_path:)
        annotation = "@route #{verb} #{path}"

        if defaults&.any?
          defaults_str = defaults.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
          annotation += " {#{defaults_str}}"
        end

        annotation += " (#{name})" if name
        annotation
      end

      # Format a single route annotation in structured format
      #
      # @param verbs [Array<String>] HTTP verbs (can be single verb for backward compatibility)
      # @param path [String] Route path
      # @param name [String] Route name
      # @param defaults [Hash] Default parameters
      # @param source_path [String] Controller file path (optional)
      # @param verb [String] Single HTTP verb (for backward compatibility)
      # @return [String] Formatted structured annotation
      def format_route_annotation_structured(path:, name:, defaults:, verbs: nil, source_path: nil, verb: nil)
        # Handle backward compatibility - if verbs not provided, use verb
        verbs ||= [verb].compact

        parts = []
        parts << path
        parts << "name: #{name}" if name

        # Format verbs - use array syntax if multiple, single if one
        if verbs.size > 1
          parts << "via: [#{verbs.join(', ')}]"
        elsif verbs.size == 1
          parts << "via: #{verbs.first}"
        end

        parts << "defaults: #{defaults.inspect}" if defaults&.any?

        "ROUTE: #{parts.join(', ')}"
      end

      # Write parsed file content back to disk
      #
      # @param path [String] File path
      # @param parsed_file [Hash] Parsed file from parser
      # @return [void]
      def write_to_file(path:, parsed_file:)
        new_content = parsed_file[:groups].pluck(:body).join
        return if parsed_file[:content] == new_content

        write_content_to_file(path: path, content: new_content)
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

      # Check if a controller file exists and contains controller classes
      #
      # @param path [String] File path
      # @return [Boolean] Whether file exists and contains controller classes
      def controller_file_exists?(path)
        return false unless File.exist?(path)

        begin
          parser_result = RailsLens::Parsers::PrismParser.parse_file(path)
          parser_result.classes.any? { |cls| cls.name.end_with?('Controller') }
        rescue RailsLens::ParseError, Errno::ENOENT, IOError
          # Fallback to filename-based detection
          File.basename(path).end_with?('_controller.rb')
        end
      end
    end
  end
end
