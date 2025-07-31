# frozen_string_literal: true

module RailsLens
  module Schema
    module Adapters
      class DatabaseInfo
        attr_reader :connection, :adapter_name

        def initialize(connection)
          @connection = connection
          @adapter_name = connection.adapter_name
        end

        def generate_annotation
          lines = []
          lines << '== Database Information'
          lines << "Adapter: #{adapter_name}"
          lines << "Database: #{database_name}"
          lines << "Version: #{database_version}"
          lines << "Encoding: #{database_encoding}" if respond_to?(:database_encoding)
          lines << "Collation: #{database_collation}" if respond_to?(:database_collation)
          lines << ''

          # Add extensions for PostgreSQL
          if adapter_name == 'PostgreSQL' && extensions.any?
            lines << 'Enabled Extensions:'
            extensions.each do |ext|
              lines << "  - #{ext['name']} (#{ext['version']})"
            end
            lines << ''
          end

          # Add schemas for PostgreSQL
          if adapter_name == 'PostgreSQL' && schemas.any?
            lines << 'Database Schemas:'
            schemas.each do |schema|
              lines << "  - #{schema}"
            end
            lines << ''
          end

          lines.join("\n")
        end

        private

        def database_name
          connection.current_database
        rescue StandardError
          'N/A'
        end

        def database_version
          case adapter_name
          when 'PostgreSQL'
            connection.select_value('SELECT version()').split[1]
          when 'Mysql2'
            connection.select_value('SELECT VERSION()')
          when 'SQLite'
            connection.select_value('SELECT sqlite_version()')
          else
            'Unknown'
          end
        rescue StandardError
          'Unknown'
        end

        def database_encoding
          case adapter_name
          when 'PostgreSQL'
            connection.select_value('SELECT pg_encoding_to_char(encoding) FROM pg_database WHERE datname = current_database()')
          when 'Mysql2'
            connection.select_value('SELECT DEFAULT_CHARACTER_SET_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = DATABASE()')
          end
        rescue StandardError
          nil
        end

        def database_collation
          case adapter_name
          when 'PostgreSQL'
            connection.select_value('SELECT datcollate FROM pg_database WHERE datname = current_database()')
          when 'Mysql2'
            connection.select_value('SELECT DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = DATABASE()')
          end
        rescue StandardError
          nil
        end

        def extensions
          return [] unless adapter_name == 'PostgreSQL'

          connection.select_all(<<-SQL.squish).to_a
            SELECT extname as name, extversion as version
            FROM pg_extension
            WHERE extname NOT IN ('plpgsql')
            ORDER BY extname
          SQL
        rescue StandardError
          []
        end

        def schemas
          return [] unless adapter_name == 'PostgreSQL'

          connection.select_values(<<-SQL.squish)
            SELECT schema_name
            FROM information_schema.schemata
            WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
            ORDER BY schema_name
          SQL
        rescue StandardError
          []
        end
      end
    end
  end
end
