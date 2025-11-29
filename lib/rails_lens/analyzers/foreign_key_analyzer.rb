# frozen_string_literal: true

module RailsLens
  module Analyzers
    class ForeignKeyAnalyzer < Base
      def analyze
        return [] unless connection.supports_foreign_keys?

        notes = []
        existing_foreign_keys = connection.foreign_keys(table_name)

        belongs_to_associations.each do |association|
          next if association.polymorphic?

          foreign_key = association.foreign_key
          referenced_table = association.klass.table_name

          unless foreign_key_exists?(foreign_key, referenced_table, existing_foreign_keys)
            notes << NoteCodes.note(foreign_key, NoteCodes::FK_CONSTRAINT)
          end
        end

        notes
      end

      private

      def belongs_to_associations
        model_class.reflect_on_all_associations(:belongs_to)
      end

      def foreign_key_exists?(column, referenced_table, existing_foreign_keys)
        existing_foreign_keys.any? do |fk|
          fk.column == column.to_s && fk.to_table == referenced_table
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
