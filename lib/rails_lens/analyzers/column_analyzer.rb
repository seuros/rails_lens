# frozen_string_literal: true

module RailsLens
  module Analyzers
    class ColumnAnalyzer < Base
      def analyze
        notes = []
        notes.concat(analyze_null_constraints)
        notes.concat(analyze_default_values)
        notes.concat(analyze_column_types)
        notes
      end

      private

      def analyze_null_constraints
        columns_needing_not_null.map do |column|
          NoteCodes.note(column.name, NoteCodes::NOT_NULL)
        end
      end

      def analyze_default_values
        notes = []

        columns.each do |column|
          if column.type == :boolean && column.default.nil? && column.null
            notes << NoteCodes.note(column.name, NoteCodes::DEFAULT)
          end

          if status_column?(column) && column.default.nil?
            notes << NoteCodes.note(column.name, NoteCodes::DEFAULT)
          end
        end

        notes
      end

      def analyze_column_types
        notes = []

        columns.each do |column|
          # Check for float columns used for money
          if money_column?(column) && column.type == :float
            notes << NoteCodes.note(column.name, NoteCodes::USE_DECIMAL)
          end

          # Check for string columns that should be integers
          if counter_column?(column) && column.type != :integer
            notes << NoteCodes.note(column.name, NoteCodes::USE_INTEGER)
          end

          # Check for inappropriately large string columns
          if column.type == :string && column.limit.nil?
            notes << NoteCodes.note(column.name, NoteCodes::LIMIT)
          end
        end

        notes
      end

      def columns_needing_not_null
        columns.select do |column|
          column.null &&
            !column.name.end_with?('_id') && # Foreign keys might be nullable
            !optional_column?(column) &&
            !timestamp_column?(column)
        end
      end

      def money_column?(column)
        column.name.match?(/price|cost|amount|fee|rate|salary|budget|revenue|profit|balance/i)
      end

      def counter_column?(column)
        column.name.end_with?('_count', '_counter', '_total')
      end

      def status_column?(column)
        column.name.match?(/status|state/i) || column.name == 'workflow_state'
      end

      def optional_column?(column)
        column.name.match?(/optional|nullable|maybe|perhaps/i) ||
          column.name.end_with?('_at', '_on', '_date') ||
          column.name.start_with?('last_', 'next_', 'previous_')
      end

      def timestamp_column?(column)
        %w[created_at updated_at deleted_at].include?(column.name)
      end

      def columns
        @columns ||= model_class.columns
      end
    end
  end
end
