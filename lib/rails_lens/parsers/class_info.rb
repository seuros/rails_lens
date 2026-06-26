# frozen_string_literal: true

module RailsLens
  module Parsers
    class ClassInfo < NodeInfo
      def matches?(class_name)
        class_name_str = class_name.to_s

        # Exact matches
        return true if name == class_name_str
        return true if full_name == class_name_str

        # Handle simple name match only if no namespace specified in query
        return true if class_name_str.exclude?('::') && (name == class_name_str)

        false
      end
    end
  end
end
