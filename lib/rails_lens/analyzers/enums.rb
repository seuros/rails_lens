# frozen_string_literal: true

module RailsLens
  module Analyzers
    class Enums < Base
      def analyze
        return nil unless model_class.respond_to?(:defined_enums) && model_class.defined_enums.any?

        lines = []
        lines << '[enums]'

        model_class.defined_enums.each do |name, values|
          # Format as TOML inline table: name = { key = "value", ... }
          formatted_values = if values.values.all? { |v| v.is_a?(Integer) }
                               # Integer-based enum
                               values.map { |k, v| "#{k} = #{v}" }.join(', ')
                             else
                               # String-based enum
                               values.map { |k, v| "#{k} = \"#{v}\"" }.join(', ')
                             end
          lines << "#{name} = { #{formatted_values} }"
        end

        lines.join("\n")
      end
    end
  end
end
