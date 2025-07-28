# frozen_string_literal: true

module RailsLens
  module Schema
    class Annotation
      MARKER_FORMAT = 'rails-lens:schema'

      attr_reader :content

      def initialize
        @content = []
      end

      def start_marker
        "# <#{MARKER_FORMAT}:begin>"
      end

      def end_marker
        "# <#{MARKER_FORMAT}:end>"
      end

      def add_line(line)
        @content << line
      end

      def add_lines(lines)
        @content.concat(lines)
      end

      def to_s
        return '' if @content.empty?

        lines = []
        lines << start_marker

        @content.each do |line|
          lines << (line.empty? ? '#' : "# #{line}")
        end

        lines << end_marker
        lines.join("\n")
      end

      def self.extract(file_content)
        start_marker = "# <#{MARKER_FORMAT}:begin>"
        end_marker = "# <#{MARKER_FORMAT}:end>"

        start_index = file_content.index(start_marker)
        return nil unless start_index

        end_index = file_content.index(end_marker, start_index)
        return nil unless end_index

        {
          start_index: start_index,
          end_index: end_index + end_marker.length,
          content: file_content[start_index..(end_index + end_marker.length - 1)]
        }
      end

      def self.remove(file_content)
        # Remove all occurrences of the annotation blocks
        result = file_content.dup

        while (annotation = extract(result))
          # Preserve one newline if the annotation was followed by a newline
          replacement = ''
          replacement = "\n" if annotation[:end_index] < result.length && result[annotation[:end_index]] == "\n"

          result[annotation[:start_index]...annotation[:end_index]] = replacement
        end

        # Clean up multiple consecutive blank lines
        result.gsub(/\n\n\n+/, "\n\n")
      end

      def self.insert_after_line(file_content, line_pattern, annotation_text)
        lines = file_content.split("\n")
        insert_index = nil

        lines.each_with_index do |line, index|
          if line.match?(line_pattern)
            insert_index = index + 1
            break
          end
        end

        return file_content unless insert_index

        # Insert the annotation
        lines.insert(insert_index, annotation_text)
        lines.join("\n")
      end

      def self.update_or_insert(file_content, annotation_text, line_pattern)
        # First, try to find and update existing annotation
        if (existing = extract(file_content))
          # Replace existing annotation
          before = file_content[0...existing[:start_index]]
          after = file_content[existing[:end_index]..]

          # Ensure proper spacing
          before = "#{before.rstrip}\n"
          after = "\n#{after.lstrip}" if after && !after.start_with?("\n")

          return before + annotation_text + after
        end

        # No existing annotation, insert new one
        insert_after_line(file_content, line_pattern, annotation_text)
      end

      def self.parse_content(annotation_block)
        return {} unless annotation_block

        lines = annotation_block.split("\n").map { |line| line.sub(/^#\s?/, '') }

        # Remove marker lines
        lines = lines[1..-2] if lines.first&.match?(/<.*:begin>/) && lines.last&.match?(/<.*:end>/)

        sections = {}
        current_section = nil
        current_content = []

        lines.each do |line|
          if line.match?(/^==\s+(.+)/)
            # Save previous section if any
            sections[current_section] = current_content.join("\n").strip if current_section

            current_section = line.strip
            current_content = []
          else
            current_content << line
          end
        end

        # Save last section
        sections[current_section] = current_content.join("\n").strip if current_section

        sections
      end
    end
  end
end
