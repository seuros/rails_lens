# frozen_string_literal: true

require_relative '../errors'
require_relative 'error_handling'

module RailsLens
  module Analyzers
    class CompositeKeys < Base
      def analyze
        # First try Rails native support
        if model_class.respond_to?(:primary_keys) && model_class.primary_keys.is_a?(Array)
          keys = model_class.primary_keys
          return format_composite_keys(keys) if keys.length > 1
        end

        # For PostgreSQL, check the actual database constraints
        if adapter_name == 'PostgreSQL'
          keys = detect_composite_primary_key_from_db
          return format_composite_keys(keys) if keys && keys.length > 1
        end

        nil
      rescue NoMethodError => e
        Rails.logger.debug { "Failed to analyze composite keys for #{model_class.name}: #{e.message}" }
        nil
      rescue ActiveRecord::ConnectionNotEstablished => e
        Rails.logger.debug { "No database connection for #{model_class.name}: #{e.message}" }
        nil
      end

      private

      def format_composite_keys(keys)
        lines = ['== Composite Primary Key']
        lines << "Primary Keys: #{keys.join(', ')}"
        lines.join("\n")
      end

      def detect_composite_primary_key_from_db
        # Query PostgreSQL system catalogs to find composite primary keys
        sql = <<-SQL.squish
          SELECT a.attname
          FROM pg_index i
          JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
          WHERE i.indrelid = '#{table_name}'::regclass
            AND i.indisprimary
          ORDER BY array_position(i.indkey, a.attnum)
        SQL

        result = connection.execute(sql)
        keys = result.pluck('attname')
        keys.empty? ? nil : keys
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.debug { "Failed to detect composite keys from database for #{table_name}: #{e.message}" }
        nil
      rescue PG::Error => e
        Rails.logger.debug { "PostgreSQL error detecting composite keys: #{e.message}" }
        nil
      end
    end
  end
end
