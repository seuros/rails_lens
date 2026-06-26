# frozen_string_literal: true

module RailsLens
  module Analyzers
    class PerformanceAnalyzer < Base
      def analyze
        notes = []
        notes.concat(analyze_uuid_indexes)
        notes.concat(analyze_query_performance)
        notes
      end

      private

      def analyze_uuid_indexes
        notes = []

        uuid_columns.each do |column|
          next if column.name == 'id' # Primary keys are already indexed

          if should_be_indexed?(column) && !indexed?(column)
            notes << NoteCodes.note(column.name, NoteCodes::INDEX)
          end
        end

        notes
      end

      def analyze_query_performance
        # Flag commonly-queried and scoped columns that lack an index
        index_notes_for(commonly_queried_columns) + index_notes_for(scoped_columns)
      end

      def index_notes_for(columns)
        columns.reject { |column| indexed?(column) }
               .map { |column| NoteCodes.note(column.name, NoteCodes::INDEX) }
      end

      def uuid_columns
        model_class.columns.select { |c| c.type == :uuid || (c.type == :string && c.name.match?(/uuid|guid/i)) }
      end

      def should_be_indexed?(column)
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
    end
  end
end
