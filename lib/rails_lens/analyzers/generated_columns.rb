# frozen_string_literal: true

module RailsLens
  module Analyzers
    class GeneratedColumns < Base
      def analyze
        return nil unless adapter_name == 'PostgreSQL'

        generated_columns = detect_generated_columns
        return nil if generated_columns.empty?

        lines = ['[generated_columns]']
        formatted = generated_columns.map do |column|
          "{ name = \"#{column[:name]}\", expr = \"#{column[:expression].to_s.gsub('"', '\\"')}\" }"
        end
        lines << "columns = [#{formatted.join(', ')}]"

        lines.join("\n")
      end

      private

      def detect_generated_columns
        # PostgreSQL system query to find generated columns
        sql = <<~SQL.squish
          SELECT
            a.attname AS column_name,
            pg_get_expr(d.adbin, d.adrelid) AS generation_expression
          FROM pg_attribute a
          JOIN pg_class c ON a.attrelid = c.oid
          LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
          WHERE c.relname = '#{table_name}'
            AND a.attgenerated != ''
            AND NOT a.attisdropped
          ORDER BY a.attnum
        SQL

        result = connection.execute(sql)
        result.map do |row|
          {
            name: row['column_name'],
            expression: row['generation_expression']
          }
        end
      rescue ActiveRecord::StatementInvalid => e
        RailsLens.logger.debug { "Failed to detect generated columns for #{table_name}: #{e.message}" }
        []
      rescue PG::Error => e
        RailsLens.logger.debug { "PostgreSQL error detecting generated columns: #{e.message}" }
        []
      end
    end
  end
end
