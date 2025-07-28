# frozen_string_literal: true

require_relative '../errors'
require_relative 'error_handling'

module RailsLens
  module Analyzers
    class Notes < Base
      def initialize(model_class)
        super
        @connection = model_class.connection
        @table_name = model_class.table_name
      rescue ActiveRecord::ConnectionNotEstablished => e
        Rails.logger.debug { "No database connection for #{model_class.name}: #{e.message}" }
        @connection = nil
        @table_name = nil
      rescue NoMethodError => e
        Rails.logger.debug { "Failed to initialize Notes analyzer for #{model_class.name}: #{e.message}" }
        @connection = nil
        @table_name = nil
      rescue RuntimeError => e
        Rails.logger.debug { "Runtime error initializing Notes analyzer for #{model_class.name}: #{e.message}" }
        @connection = nil
        @table_name = nil
      end

      def analyze
        return nil unless @connection && @table_name

        notes = []

        notes.concat(analyze_indexes)
        notes.concat(analyze_foreign_keys)
        notes.concat(analyze_associations)
        notes.concat(analyze_columns)
        notes.concat(analyze_performance)
        notes.concat(analyze_best_practices)

        notes.compact.uniq
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.debug { "Database error analyzing notes for #{@table_name}: #{e.message}" }
        nil
      rescue NoMethodError => e
        Rails.logger.debug { "Method error analyzing notes for #{@table_name}: #{e.message}" }
        nil
      end

      private

      def analyze_indexes
        notes = []

        # Check for missing indexes on foreign keys
        foreign_key_columns.each do |column|
          notes << "Missing index on foreign key '#{column}'" unless has_index?(column)
        end

        # Check for missing composite indexes
        common_query_patterns.each do |columns|
          unless has_composite_index?(columns)
            notes << "Consider composite index on (#{columns.join(', ')}) for common queries"
          end
        end

        # Check for redundant indexes
        redundant_indexes.each do |index|
          notes << "Index '#{index.name}' might be redundant"
        end

        notes
      end

      def analyze_foreign_keys
        notes = []

        # Check for missing foreign key constraints
        belongs_to_associations.each do |association|
          column = association.foreign_key
          next unless column_exists?(column)

          unless has_foreign_key_constraint?(column)
            notes << "Missing foreign key constraint for '#{column}' (#{association.name})"
          end
        end

        notes
      end

      def analyze_associations
        # Check for missing inverse_of
        notes = associations_needing_inverse.map do |association|
          "Association '#{association.name}' should specify inverse_of"
        end

        # Check for N+1 query risks
        has_many_associations.each do |association|
          if likely_n_plus_one?(association)
            notes << "Association '#{association.name}' has N+1 query risk - consider includes/preload"
          end
        end

        # Check for missing counter caches
        associations_needing_counter_cache.each do |association|
          notes << "Consider adding counter cache for '#{association.name}'"
        end

        notes
      end

      def analyze_columns
        # Check for missing NOT NULL constraints
        notes = columns_needing_not_null.map do |column|
          "Column '#{column.name}' should probably have NOT NULL constraint"
        end

        # Check for missing defaults
        columns_needing_defaults.each do |column|
          notes << "Column '#{column.name}' should have a default value"
        end

        # Check for inappropriate column types
        columns.each do |column|
          if column.name.end_with?('_count') && column.type != :integer
            notes << "Counter column '#{column.name}' should be integer type"
          end

          if column.name.match?(/price|amount|cost/) && column.type == :float
            notes << "Monetary column '#{column.name}' should use decimal type, not float"
          end
        end

        notes
      end

      def analyze_performance
        # Large text columns without separate storage
        notes = large_text_columns.map do |column|
          "Large text column '#{column.name}' might benefit from separate storage"
        end

        # Polymorphic associations without indexes
        polymorphic_associations.each do |association|
          # For polymorphic belongs_to associations
          next unless association.macro == :belongs_to && association.polymorphic?

          foreign_key = association.foreign_key.to_s
          type_column = "#{association.foreign_type || association.name}_type"
          unless has_composite_index?([foreign_key, type_column])
            notes << "Polymorphic association '#{association.name}' needs composite index on (#{foreign_key}, #{type_column})"
          end
        end

        # UUID columns without proper indexes
        uuid_columns.each do |column|
          if column.name.end_with?('_id') && !has_index?(column.name)
            notes << "UUID column '#{column.name}' needs an index"
          end
        end

        notes
      end

      def analyze_best_practices
        notes = []

        # Check for updated_at/created_at
        notes << "Missing 'created_at' timestamp column" unless column_exists?('created_at')

        notes << "Missing 'updated_at' timestamp column" unless column_exists?('updated_at')

        # Check for soft deletes without index
        if column_exists?('deleted_at') && !has_index?('deleted_at')
          notes << "Soft delete column 'deleted_at' needs an index"
        end

        # Check for STI without index
        if model_class.inheritance_column && column_exists?(model_class.inheritance_column) && !has_index?(model_class.inheritance_column)
          notes << "STI column '#{model_class.inheritance_column}' needs an index"
        end

        notes
      end

      # Helper methods

      def columns
        @columns ||= connection.columns(table_name)
      end

      def indexes
        @indexes ||= connection.indexes(table_name)
      end

      def foreign_keys
        @foreign_keys ||= if connection.respond_to?(:foreign_keys)
                            connection.foreign_keys(table_name)
                          else
                            []
                          end
      end

      def associations
        @associations ||= model_class.reflect_on_all_associations
      end

      def belongs_to_associations
        associations.select { |a| a.macro == :belongs_to }
      end

      def has_many_associations
        associations.select { |a| a.macro == :has_many }
      end

      def polymorphic_associations
        associations.select(&:polymorphic?)
      end

      def column_exists?(column_name)
        columns.any? { |c| c.name == column_name.to_s }
      end

      def has_index?(column_name)
        indexes.any? { |index| index.columns.include?(column_name.to_s) }
      end

      def has_composite_index?(column_names)
        indexes.any? { |index| index.columns == column_names.map(&:to_s) }
      end

      def has_foreign_key_constraint?(column_name)
        foreign_keys.any? { |fk| fk.column == column_name.to_s }
      end

      def foreign_key_columns
        columns.select { |c| c.name.end_with?('_id') }.map(&:name)
      end

      def common_query_patterns
        patterns = []

        # Common patterns for most models
        patterns << %w[user_id created_at] if column_exists?('created_at') && column_exists?('user_id')

        patterns << %w[status created_at] if column_exists?('status') && column_exists?('created_at')

        patterns
      end

      def redundant_indexes
        redundant = []

        indexes.each do |index|
          indexes.each do |other_index|
            next if index.name == other_index.name

            # Check if index is a prefix of other_index
            redundant << index if other_index.columns[0...index.columns.length] == index.columns
          end
        end

        redundant.uniq
      end

      def associations_needing_inverse
        associations.select do |association|
          association.options[:inverse_of].nil? &&
            !association.options[:through] &&
            !association.options[:as] &&
            association.macro != :has_and_belongs_to_many
        end
      end

      def likely_n_plus_one?(association)
        # Simple heuristic: has_many without conditions/scopes that would limit results
        association.macro == :has_many &&
          !association.options[:limit] &&
          !association.scope
      end

      def associations_needing_counter_cache
        belongs_to_associations.select do |association|
          # Check if the inverse association exists and is commonly counted
          inverse = association.klass.reflect_on_association(association.inverse_of&.name || model_class.name.underscore.pluralize)
          inverse && inverse.macro == :has_many && !association.options[:counter_cache]
        rescue NameError => e
          Rails.logger.debug { "Failed to check counter cache for association: #{e.message}" }
          false
        rescue NoMethodError => e
          Rails.logger.debug { "Method error checking counter cache: #{e.message}" }
          false
        end
      end

      def columns_needing_not_null
        columns.select do |column|
          column.null &&
            !column.name.end_with?('_at') &&
            !column.name.end_with?('_id') &&
            %w[id created_at updated_at].exclude?(column.name) &&
            column.type != :text &&
            column.type != :json
        end
      end

      def columns_needing_defaults
        columns.select do |column|
          column.default.nil? &&
            column.type == :boolean
        end
      end

      def large_text_columns
        columns.select do |column|
          %i[text json jsonb].include?(column.type)
        end
      end

      def uuid_columns
        columns.select do |column|
          column.type == :uuid || (column.type == :string && column.name.match?(/uuid|guid/))
        end
      end
    end
  end
end
