# frozen_string_literal: true

module RailsLens
  module Analyzers
    class BestPracticesAnalyzer < Base
      def analyze
        notes = []
        notes.concat(analyze_timestamps)
        notes.concat(analyze_soft_deletes)
        notes.concat(analyze_sti_columns)
        notes.concat(analyze_naming_conventions)
        notes
      end

      private

      def analyze_timestamps
        notes = []

        notes << 'Missing timestamp columns (created_at, updated_at)' unless has_timestamps?

        if has_column?('created_at') && !has_column?('updated_at')
          notes << 'Has created_at but missing updated_at'
        elsif !has_column?('created_at') && has_column?('updated_at')
          notes << 'Has updated_at but missing created_at'
        end

        notes
      end

      def analyze_soft_deletes
        notes = []

        soft_delete_columns.each do |column|
          notes << "Soft delete column '#{column.name}' should be indexed" unless indexed?(column)
        end

        notes
      end

      def analyze_sti_columns
        notes = []

        if sti_model? && type_column
          notes << "STI type column '#{type_column.name}' should be indexed" unless indexed?(type_column)

          notes << "STI type column '#{type_column.name}' should have NOT NULL constraint" if type_column.null
        end

        notes
      end

      def analyze_naming_conventions
        notes = []

        # Check for non-conventional column names
        columns.each do |column|
          if column.name.match?(/^(is|has)_/i)
            notes << "Column '#{column.name}' uses non-conventional prefix - consider removing 'is_' or 'has_'"
          end

          if column.name.match?(/Id$/) # Capital I
            notes << "Column '#{column.name}' should use snake_case (e.g., '#{column.name.underscore}')"
          end
        end

        # Check table naming
        # Extract the actual table name without schema prefix for PostgreSQL
        # PostgreSQL uses schema.table format (e.g., "ai.skills" -> "skills")
        unqualified_table = table_name.to_s.split('.').last

        if !unqualified_table.match?(/^[a-z_]+$/) || unqualified_table != unqualified_table.pluralize
          notes << "Table name '#{table_name}' doesn't follow Rails conventions (should be plural, snake_case)"
        end

        notes
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
