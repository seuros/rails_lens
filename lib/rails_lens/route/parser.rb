# frozen_string_literal: true

module RailsLens
  module Route
    # Handles parsing controller files and groups lines into categories
    class Parser
      class << self
        # Parse a controller file and return grouped content
        #
        # @param path [String] File path to parse
        # @param actions [Array<String>] List of valid actions for this controller
        # @return [Hash] { content => String, groups => Array<Hash> }
        def call(path:, actions:)
          groups = []
          group = {}
          content = File.read(path)

          content.each_line.with_index do |line, index|
            parsed_line = parse_line(line: line, actions: actions)

            if group[:type] == parsed_line[:type]
              # Same group. Push the current line into the current group.
              group[:body] += line
            else
              # Now looking at a new group. Push the current group onto the array
              # and start a new one.
              groups.push(group) unless group.empty?
              group = parsed_line.merge(line_number: index + 1)
            end
          end

          # Push the last group onto the array and return.
          groups.push(group)
          { content: content, groups: groups }
        end

        private

        # Parse a single line and determine its type
        #
        # @param line [String] A line of a file
        # @param actions [Array<String>] List of valid actions for this controller
        # @return [Hash] { type => Symbol, body => String, action => String }
        def parse_line(line:, actions:)
          comment_match = /^\s*#.*$/.match(line)
          def_match = /^\s*def\s+(\w*)\s*\w*.*$/.match(line)

          if comment_match
            { type: :comment, body: line, action: nil }
          elsif def_match && actions.include?(def_match[1])
            { type: :action, body: line, action: def_match[1] }
          else
            { type: :code, body: line, action: nil }
          end
        end
      end
    end
  end
end
