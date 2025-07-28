# frozen_string_literal: true

module RailsLens
  module Analyzers
    class Enums < Base
      def analyze
        return nil unless model_class.respond_to?(:defined_enums) && model_class.defined_enums.any?

        lines = []
        lines << '== Enums'

        model_class.defined_enums.each do |name, values|
          # Detect if it's using integer or string values
          formatted_values = if values.values.all? { |v| v.is_a?(Integer) }
                               # Integer-based enum
                               values.map { |k, v| "#{k}: #{v}" }.join(', ')
                             else
                               # String-based enum
                               values.map { |k, v| "#{k}: \"#{v}\"" }.join(', ')
                             end
          lines << "- #{name}: { #{formatted_values} }"

          # Add column type if we can detect it
          if model_class.table_exists? && model_class.columns_hash[name.to_s]
            column = model_class.columns_hash[name.to_s]
            lines.last << " (#{column.type})"
          end
        end

        lines.join("\n")
      end
    end
  end
end
