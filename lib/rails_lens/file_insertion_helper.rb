# frozen_string_literal: true

module RailsLens
  # Helper class to handle file insertion logic, particularly for inserting content
  # after frozen_string_literal comments while maintaining proper formatting
  class FileInsertionHelper
    FROZEN_STRING_LITERAL_REGEX = /^# frozen_string_literal: true$/

    class << self
      # Insert content at a specific class definition location
      #
      # @param file_path [String] Path to the file
      # @param class_name [String] Name of the class to find
      # @param annotation [String] The annotation to insert
      # @return [Boolean] Whether insertion was successful
      def insert_at_class_definition(file_path, _class_name, annotation)
        return false unless File.exist?(file_path)

        original_content = File.read(file_path)
        content = original_content

        # First remove any existing annotations (schema + the marker we're inserting)
        content = remove_existing_annotations(content, annotation)

        modified_content = insert_after_frozen_string_literal(content, annotation)
        return false if modified_content == original_content

        File.write(file_path, modified_content)
        true
      rescue StandardError
        false
      end

      # Insert content at a specific line number
      #
      # @param file_path [String] Path to the file
      # @param line_number [Integer] Line number where class is defined
      # @param annotation [String] The annotation to insert
      # @return [Boolean] Whether insertion was successful
      def insert_at_line(file_path, line_number, annotation)
        original_content = File.read(file_path)
        content = original_content

        # First remove any existing annotations (schema + the marker we're inserting)
        content = remove_existing_annotations(content, annotation)

        lines = content.split("\n", -1) # Preserve trailing newlines

        # Find correct insertion point considering frozen_string_literal
        insert_index = find_insertion_point_for_line(lines, line_number)

        lines.insert(insert_index, annotation)

        # Preserve original line ending
        result = lines.join("\n")
        result += "\n" if content.end_with?("\n") && !result.end_with?("\n")
        return false if result == original_content

        File.write(file_path, result)
        true
      rescue StandardError
        false
      end

      # Insert content after frozen_string_literal comment with proper spacing
      #
      # @param content [String] The original file content
      # @param insertion_content [String] The content to insert
      # @return [String] The modified content
      def insert_after_frozen_string_literal(content, insertion_content)
        # First check if frozen_string_literal exists
        unless content.match?(/^# frozen_string_literal: true/)
          # If no frozen_string_literal, insert at the beginning with newline
          return "#{insertion_content}\n#{content}"
        end

        lines = content.split("\n", -1) # Preserve empty lines
        insert_index = find_frozen_string_literal_index(lines)

        return content unless insert_index

        # Ensure proper spacing after frozen_string_literal
        insert_index = ensure_blank_line_after_frozen_literal(lines, insert_index)

        # Insert the new content
        lines.insert(insert_index, insertion_content)

        # Preserve original line ending
        result = lines.join("\n")
        result += "\n" if content.end_with?("\n") && !result.end_with?("\n")

        result
      end

      # Remove content that was inserted after frozen_string_literal
      #
      # @param content [String] The file content
      # @param marker_start [String] Start marker to identify content to remove
      # @param marker_end [String] End marker to identify content to remove
      # @return [String] The content with insertion removed
      def remove_after_frozen_string_literal(content, marker_start, marker_end)
        # Use regex to remove the marked content
        pattern = /^.*#{Regexp.escape(marker_start)}.*$\n(.*\n)*?^.*#{Regexp.escape(marker_end)}.*$\n/
        content.gsub(pattern, '')
      end

      private

      # Strip existing annotation blocks before re-inserting, so repeated runs
      # don't stack duplicate blocks. Removes the legacy schema block and, when
      # the annotation being inserted carries its own marker family (e.g. an
      # extension's "rails-lens:graph"), an existing block of that same family.
      #
      # @param content [String] the current file content
      # @param annotation [String] the annotation block about to be inserted
      # @return [String] content with matching existing blocks removed
      def remove_existing_annotations(content, annotation)
        # Legacy behavior: always clear schema annotations.
        content = Schema::Annotation.remove(content) if Schema::Annotation.extract(content)

        # Clear an existing block of the same marker family (e.g. rails-lens:graph).
        marker = annotation[/<(rails-lens:[\w-]+):begin>/, 1]
        if marker && marker != Schema::Annotation::MARKER_FORMAT
          content = remove_after_frozen_string_literal(content, "<#{marker}:begin>", "<#{marker}:end>")
                    .gsub(/\n{3,}/, "\n\n")
        end

        content
      end

      # Find the correct insertion point for a line, considering frozen_string_literal
      #
      # @param lines [Array<String>] Array of file lines
      # @param line_number [Integer] Target line number (1-based)
      # @return [Integer] Index where annotation should be inserted
      def find_insertion_point_for_line(lines, line_number)
        # Convert 1-based line number to 0-based index
        target_index = line_number - 1

        # Ensure target_index is within bounds
        target_index = 0 if target_index.negative?
        target_index = lines.length if target_index > lines.length

        # Insert before the class definition line
        insert_index = target_index

        # If previous line is a comment (but not frozen_string_literal), insert before it
        while insert_index.positive? &&
              lines[insert_index - 1].strip.start_with?('#') &&
              !lines[insert_index - 1].match?(FROZEN_STRING_LITERAL_REGEX)
          insert_index -= 1
        end

        # Ensure we have a blank line before the annotation if needed
        if insert_index.positive? && !lines[insert_index - 1].strip.empty?
          lines.insert(insert_index, '')
          insert_index += 1
        end

        insert_index
      end

      # Find the index of the frozen_string_literal line
      #
      # @param lines [Array<String>] Array of file lines
      # @return [Integer, nil] Index after the frozen_string_literal line
      def find_frozen_string_literal_index(lines)
        lines.each_with_index do |line, index|
          return index + 1 if line.match?(FROZEN_STRING_LITERAL_REGEX)
        end
        nil
      end

      # Ensure there's a blank line after frozen_string_literal
      #
      # @param lines [Array<String>] Array of file lines
      # @param insert_index [Integer] Index where we want to insert
      # @return [Integer] Updated insert index
      def ensure_blank_line_after_frozen_literal(lines, insert_index)
        if insert_index < lines.length && !lines[insert_index].strip.empty?
          # No blank line exists, add one
          lines.insert(insert_index, '')
        elsif insert_index >= lines.length
          # At end of file, add blank line
          lines.insert(insert_index, '')
        else
          # There's already a blank line, move past it
        end
        insert_index += 1

        insert_index
      end
    end
  end
end
