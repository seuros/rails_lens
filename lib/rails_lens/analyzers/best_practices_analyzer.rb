# frozen_string_literal: true

module RailsLens
  module Analyzers
    class BestPracticesAnalyzer < Base
      def analyze
        notes = []
        notes.concat(analyze_timestamps)
        notes.concat(analyze_soft_deletes)
        notes.concat(analyze_sti_columns)
        notes.concat(analyze_large_text_columns)
        notes
      end

      private

      def analyze_timestamps
        notes = []

        notes << NoteCodes::NO_TIMESTAMPS unless has_timestamps?

        if has_column?('created_at') && !has_column?('updated_at')
          notes << NoteCodes::PARTIAL_TS
        elsif !has_column?('created_at') && has_column?('updated_at')
          notes << NoteCodes::PARTIAL_TS
        end

        notes
      end

      def analyze_soft_deletes
        soft_delete_columns.reject { |col| indexed?(col) }.map do |column|
          NoteCodes.note(column.name, NoteCodes::INDEX)
        end
      end

      def analyze_sti_columns
        notes = []

        if sti_model? && type_column
          notes << NoteCodes.note(type_column.name, NoteCodes::INDEX) unless indexed?(type_column)
          notes << NoteCodes.note(type_column.name, NoteCodes::STI_NOT_NULL) if type_column.null
        end

        notes
      end

      def analyze_large_text_columns
        columns.select { |c| c.type == :text }.map do |column|
          NoteCodes.note(column.name, NoteCodes::STORAGE)
        end
      end

      def has_timestamps?
        has_column?('created_at') && has_column?('updated_at')
      end

      def soft_delete_columns
        columns.select { |c| c.name.match?(/deleted_at|archived_at|discarded_at/i) }
      end

      def sti_model?
        model_class.base_class != model_class || has_column?('type')
      end

      def type_column
        columns.find { |c| c.name == 'type' }
      end

      def has_column?(name)
        model_class.column_names.include?(name)
      end

      def indexed?(column)
        connection.indexes(table_name).any? do |index|
          index.columns.include?(column.name)
        end
      end

      def columns
        @columns ||= model_class.columns
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
