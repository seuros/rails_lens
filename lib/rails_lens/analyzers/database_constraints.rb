# frozen_string_literal: true

require_relative '../errors'
require_relative 'error_handling'

module RailsLens
  module Analyzers
    class DatabaseConstraints < Base
      def analyze
        return nil unless connection.respond_to?(:check_constraints)

        constraints = []

        # Get check constraints
        check_constraints = connection.check_constraints(table_name)
        return nil if check_constraints.empty?

        constraints << '== Check Constraints'
        check_constraints.each do |constraint|
          name = constraint.options[:name] || constraint.name
          expression = constraint.expression || constraint.options[:validate]
          constraints << "- #{name}: #{expression}"
        end

        constraints.empty? ? nil : constraints.join("\n")
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.debug { "Failed to fetch check constraints for #{table_name}: #{e.message}" }
        nil
      rescue NoMethodError => e
        Rails.logger.debug { "Check constraints not supported by adapter: #{e.message}" }
        nil
      end
    end
  end
end
