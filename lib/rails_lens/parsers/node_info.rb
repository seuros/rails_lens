# frozen_string_literal: true

module RailsLens
  module Parsers
    # Shared metadata for a parsed class or module definition.
    class NodeInfo
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

      def to_s
        full_name
      end

      def inspect
        "#<#{self.class.name.split('::').last} name=#{name} line=#{line_number} namespace=#{namespace}>"
      end
    end
  end
end
