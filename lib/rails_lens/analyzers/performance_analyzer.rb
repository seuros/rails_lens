# frozen_string_literal: true

module RailsLens
  module Analyzers
    class PerformanceAnalyzer < Base
      def analyze
        notes = []
        notes.concat(analyze_large_text_columns)
        notes.concat(analyze_uuid_indexes)
        notes.concat(analyze_query_performance)
        notes
      end

      private

      def analyze_large_text_columns
        notes = []

        text_columns.each do |column|
          if frequently_queried_column?(column)
            notes << "Large text column '#{column.name}' is frequently queried - consider separate storage"
          end
        end

        notes
      end

      def analyze_uuid_indexes
        notes = []

        uuid_columns.each do |column|
          next if column.name == 'id' # Primary keys are already indexed

          if should_be_indexed?(column) && !indexed?(column)
            notes << "UUID column '#{column.name}' should be indexed for better query performance"
          end
        end

        notes
      end

      def analyze_query_performance
        notes = []

        # Check for columns that are commonly used in WHERE clauses
        commonly_queried_columns.each do |column|
          next if indexed?(column)

          notes << "Column '#{column.name}' is commonly used in queries - consider adding an index"
        end

        # Check for missing indexes on scoped columns
        scoped_columns.each do |column|
          next if indexed?(column)

          notes << "Scope column '#{column.name}' should be indexed"
        end

        notes
      end

      def text_columns
        model_class.columns.select { |c| c.type == :text }
      end

      def uuid_columns
        model_class.columns.select { |c| c.type == :uuid || (c.type == :string && c.name.match?(/uuid|guid/i)) }
      end

      def frequently_queried_column?(column)
        # Heuristic: columns with certain names are likely to be queried frequently
        column.name.match?(/title|name|slug|description|summary|content|body/i)
      end

      def should_be_indexed?(column)
        # UUID columns used as foreign keys or identifiers should be indexed
        column.name.end_with?('_id', '_uuid', '_guid') ||
          column.name.match?(/identifier|reference|token/i)
      end

      def commonly_queried_columns
        model_class.columns.select do |column|
          column.name.match?(/email|username|slug|token|code|status|state|type/i) ||
            column.name.end_with?('_type', '_kind', '_category')
        end
      end

      def scoped_columns
        model_class.columns.select do |column|
          column.name.match?(/scope|tenant|company|organization|account|workspace/i) &&
            column.name.end_with?('_id')
        end
      end

      def indexed?(column)
        connection.indexes(table_name).any? do |index|
          index.columns.include?(column.name)
        end
      end

      def connection
        model_class.connection
      end

      def table_name
        model_class.table_name
      end
    end
  end
end
