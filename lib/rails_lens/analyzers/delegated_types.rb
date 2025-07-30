# frozen_string_literal: true

require_relative '../errors'
require_relative 'error_handling'

module RailsLens
  module Analyzers
    class DelegatedTypes < Base
      def analyze
        return nil unless delegated_type_model?

        lines = ['== Delegated Type']

        # Find delegated type configuration
        delegated_type_info = find_delegated_type_info
        return nil unless delegated_type_info

        lines << "Type Column: #{delegated_type_info[:type_column]}"
        lines << "ID Column: #{delegated_type_info[:id_column]}"
        types_list = if delegated_type_info[:types].respond_to?(:keys)
                       delegated_type_info[:types].keys
                     else
                       Array(delegated_type_info[:types])
                     end
        lines << "Types: #{types_list.join(', ')}"

        lines.join("\n")
      end

      private

      def delegated_type_model?
        # Check if model uses delegated_type by looking for the Rails-provided class methods
        # Rails delegated_type creates a "prefix_types" class method

        # Skip abstract models that don't have tables configured
        return false unless model_class.respond_to?(:table_exists?) && model_class.table_exists?

        columns = model_class.column_names

        # Look for columns ending with _type that have corresponding _id columns
        # and check if the model has the corresponding delegated type class method
        columns.any? do |col|
          if col.end_with?('_type')
            prefix = col.sub(/_type$/, '')
            if columns.include?("#{prefix}_id")
              # Check if Rails delegated_type created the "prefix_types" class method
              model_class.respond_to?("#{prefix}_types")
            end
          end
        end
      end

      def find_delegated_type_info
        # Find columns that match the delegated type pattern and have the Rails class method
        # Skip abstract models that don't have tables configured
        return nil unless model_class.respond_to?(:table_exists?) && model_class.table_exists?

        columns = model_class.column_names

        # Find the delegated type by checking for the Rails-provided class method
        delegated_info = nil
        columns.each do |col|
          next unless col.end_with?('_type')

          prefix = col.sub(/_type$/, '')
          id_column = "#{prefix}_id"

          next unless columns.include?(id_column) && model_class.respond_to?("#{prefix}_types")

          # Use the Rails-provided method to get the types
          types = model_class.send("#{prefix}_types")

          delegated_info = {
            type_column: col,
            id_column: id_column,
            types: types
          }
          break
        end

        delegated_info
      rescue NoMethodError => e
        Rails.logger.debug { "Failed to find delegated type info for #{model_class.name}: #{e.message}" }
        nil
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.debug { "Database error finding delegated type info: #{e.message}" }
        nil
      end

      def polymorphic_association?(prefix)
        # Check if this is a polymorphic association by looking at the model's reflections
        model_class.reflections.values.any? do |reflection|
          reflection.polymorphic? && reflection.name.to_s == prefix
        end
      end

      def infer_delegated_types(prefix)
        # First try to read from the model file to find delegated_type declaration
        model_file = "app/models/#{model_class.name.underscore}.rb"
        if File.exist?(model_file)
          content = File.read(model_file)
          if (match = content.match(/delegated_type\s+:#{prefix}.*types:\s*%(w|W)\[([^\]]+)\]/))
            types_string = match[2]
            return types_string.scan(/\w+/)
          end
        end

        # Fallback to database
        if model_class.table_exists?
          model_class
            .where.not("#{prefix}_type" => nil)
            .distinct
            .pluck("#{prefix}_type")
            .compact
            .sort
        else
          []
        end
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.debug { "Database error inferring delegated types: #{e.message}" }
        []
      rescue Errno::ENOENT => e
        Rails.logger.debug { "File not found when inferring delegated types: #{e.message}" }
        []
      end
    end
  end
end
