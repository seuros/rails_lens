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
    end
  end
end
