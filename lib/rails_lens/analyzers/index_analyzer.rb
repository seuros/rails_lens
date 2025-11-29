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

          notes << NoteCodes.note(column, NoteCodes::INDEX)
        end

        # Check for missing indexes on polymorphic associations
        polymorphic_associations.each do |assoc|
          type_column = "#{assoc.name}_type"
          id_column = "#{assoc.name}_id"

          unless composite_index_exists?([type_column, id_column])
            notes << NoteCodes.note(assoc.name.to_s, NoteCodes::POLY_INDEX)
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
              notes << NoteCodes.note(index.name, NoteCodes::REDUND_IDX)
            end
          end
        end

        notes
      end

      def analyze_composite_indexes
        notes = []

        association_pairs = model_class.reflect_on_all_associations(:belongs_to)
                                       .combination(2)
                                       .select { |a, b| common_query_pattern?(a, b) }

        association_pairs.each do |assoc1, assoc2|
          columns = [assoc1.foreign_key, assoc2.foreign_key].sort
          unless composite_index_exists?(columns)
            notes << NoteCodes.note(columns.join('+'), NoteCodes::COMP_INDEX)
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
        return false if index1.unique != index2.unique

        if index1.columns.length < index2.columns.length
          index2.columns[0...index1.columns.length] == index1.columns
        else
          index1.columns[0...index2.columns.length] == index2.columns
        end
      end

      def common_query_pattern?(assoc1, assoc2)
        assoc1.class_name == assoc2.class_name ||
          related_models?(assoc1.class_name, assoc2.class_name)
      end

      def related_models?(class1, class2)
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
