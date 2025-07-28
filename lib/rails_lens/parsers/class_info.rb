# frozen_string_literal: true

module RailsLens
  module Parsers
    class ClassInfo
      attr_reader :name, :line_number, :column, :end_line, :namespace

      def initialize(name:, line_number:, column:, end_line:, namespace: nil)
        @name = name
        @line_number = line_number
        @column = column
        @end_line = end_line
        @namespace = namespace
      end

      def full_name
        if namespace.present?
          "#{namespace}::#{name}"
        else
          name
        end
      end

      def matches?(class_name)
        class_name_str = class_name.to_s

        # Exact matches
        return true if name == class_name_str
        return true if full_name == class_name_str

        # Handle simple name match only if no namespace specified in query
        return true if class_name_str.exclude?('::') && (name == class_name_str)

        false
      end

      def to_s
        full_name
      end

      def inspect
        "#<ClassInfo name=#{name} line=#{line_number} namespace=#{namespace}>"
      end
    end
  end
end
