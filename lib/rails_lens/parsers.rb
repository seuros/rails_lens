# frozen_string_literal: true

module RailsLens
  module Parsers
    # Main entry point for parsing functionality
    def self.parse_file(file_path)
      PrismParser.parse_file(file_path)
    end
  end
end
