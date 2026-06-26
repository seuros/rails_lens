# frozen_string_literal: true

require_relative 'error_handling'

module RailsLens
  module Analyzers
    class Base
      include ErrorHandling

      attr_reader :model_class

      def initialize(model_class)
        @model_class = model_class
      end

      def analyze
        raise NotImplementedError, 'Subclasses must implement #analyze'
      end

      protected

      def table_name
        @table_name ||= model_class.table_name
      end

      def connection
        @connection ||= model_class.connection
      end

      def adapter_name
        @adapter_name ||= connection.adapter_name
      end

      def indexed?(column)
        connection.indexes(table_name).any? do |index|
          index.columns.include?(column.name)
        end
      end

      def needs_explicit_inverse_of?(association)
        # Rails can auto-infer inverse_of for vanilla associations
        # Only require explicit inverse_of when using custom options
        association.options[:class_name].present? ||
          association.options[:foreign_key].present? ||
          association.options[:as].present? ||
          association.options[:source].present? ||
          association.options[:through].present?
      end
    end
  end
end
