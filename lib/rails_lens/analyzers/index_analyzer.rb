# frozen_string_literal: true

module RailsLens
  module Analyzers
    class IndexAnalyzer < Base
      def analyze
        notes = []
        notes.concat(analyze_missing_indexes)
        notes.concat(analyze_redundant_indexes)
        notes.concat(analyze_composite_indexes)
        notes
      end

      private

      def analyze_missing_indexes
        notes = []

        # Check for missing indexes on foreign keys
        foreign_key_columns.each do |column|
          next if indexed?(column)

          notes << "Missing index on foreign key '#{column}'"
        end

        # Check for missing indexes on polymorphic associations
        polymorphic_associations.each do |assoc|
          type_column = "#{assoc.name}_type"
          id_column = "#{assoc.name}_id"

          unless composite_index_exists?([type_column, id_column])
            notes << "Missing composite index on polymorphic association '#{assoc.name}' columns [#{type_column}, #{id_column}]"
          end
        end

        notes
      end

      def analyze_redundant_indexes
        notes = []
        indexes = connection.indexes(table_name)

        indexes.each_with_index do |index, i|
          indexes[(i + 1)..].each do |other_index|
            if index_redundant?(index, other_index)
              notes << "Index '#{index.name}' might be redundant with '#{other_index.name}'"
            end
          end
        end

        notes
      end

      def analyze_composite_indexes
        notes = []

        # Check for common query patterns that could benefit from composite indexes
        association_pairs = model_class.reflect_on_all_associations(:belongs_to)
                                       .combination(2)
                                       .select { |a, b| common_query_pattern?(a, b) }

        association_pairs.each do |assoc1, assoc2|
          columns = [assoc1.foreign_key, assoc2.foreign_key].sort
          unless composite_index_exists?(columns)
            notes << "Consider composite index on [#{columns.join(', ')}] for common query pattern"
          end
        end

        notes
      end

      def foreign_key_columns
        model_class.reflect_on_all_associations(:belongs_to)
                   .reject(&:polymorphic?)
                   .map(&:foreign_key)
      end

      def polymorphic_associations
        model_class.reflect_on_all_associations(:belongs_to)
                   .select(&:polymorphic?)
      end

      def indexed?(column)
        connection.indexes(table_name).any? do |index|
          index.columns.include?(column.to_s)
        end
      end

      def composite_index_exists?(columns)
        connection.indexes(table_name).any? do |index|
          index.columns == columns.map(&:to_s)
        end
      end

      def index_redundant?(index1, index2)
        # An index is redundant if it's a prefix of another index
        return false if index1.unique != index2.unique

        if index1.columns.length < index2.columns.length
          index2.columns[0...index1.columns.length] == index1.columns
        else
          index1.columns[0...index2.columns.length] == index2.columns
        end
      end

      def common_query_pattern?(assoc1, assoc2)
        # This is a simplified heuristic - in a real app, you might analyze actual queries
        # For now, we'll assume associations to the same model or related models are commonly queried together
        assoc1.class_name == assoc2.class_name ||
          related_models?(assoc1.class_name, assoc2.class_name)
      end

      def related_models?(class1, class2)
        # Simple heuristic: models are related if they share a common prefix
        # e.g., "UserProfile" and "UserSettings" are likely related
        class1.split('::').last[/^[A-Z][a-z]+/] == class2.split('::').last[/^[A-Z][a-z]+/]
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
