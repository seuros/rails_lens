# frozen_string_literal: true

module RailsLens
  module Analyzers
    class DatabaseConstraints < Base
      def analyze
        return nil unless connection.respond_to?(:check_constraints)

        constraints = []

        # Get check constraints
        check_constraints = connection.check_constraints(table_name)
        return nil if check_constraints.empty?

        constraints << '[check_constraints]'
        formatted = check_constraints.map do |constraint|
          name = constraint.options[:name] || constraint.name
          expression = constraint.expression || constraint.options[:validate]
          "{ name = \"#{name}\", expr = \"#{expression.to_s.gsub('"', '\\"')}\" }"
        end
        constraints << "constraints = [#{formatted.join(', ')}]"

        constraints.empty? ? nil : constraints.join("\n")
      rescue ActiveRecord::StatementInvalid => e
        RailsLens.logger.debug { "Failed to fetch check constraints for #{table_name}: #{e.message}" }
        nil
      rescue NoMethodError => e
        RailsLens.logger.debug { "Check constraints not supported by adapter: #{e.message}" }
        nil
      end
    end
  end
end
