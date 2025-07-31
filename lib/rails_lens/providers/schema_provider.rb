# frozen_string_literal: true

module RailsLens
  module Providers
    class SchemaProvider < Base
      def type
        :schema
      end

      def applicable?(_model_class)
        true # Always applicable - handles both abstract and regular models
      end

      def process(model_class, connection = nil)
        # Always require a connection to be passed to prevent connection pool exhaustion
        if connection.nil?
          raise ArgumentError, 'SchemaProvider requires a connection to be passed to prevent connection pool exhaustion'
        end

        conn = connection

        if model_class.abstract_class?
          # For abstract classes, show database connection information in TOML format
          adapter_name = conn.adapter_name

          lines = []

          # Get connection name
          begin
            connection_name = conn.pool.db_config.name
            lines << "connection = \"#{connection_name}\""
          rescue StandardError
            lines << 'connection = "unknown"'
          end

          lines << "database_dialect = \"#{adapter_name}\""

          # Add database version information
          begin
            db_version = conn.database_version
            lines << "database_version = \"#{db_version}\""
          rescue StandardError
            lines << 'database_version = "unknown"'
          end

          # Add database name if available
          begin
            db_name = conn.current_database
            lines << "database_name = \"#{db_name}\"" if db_name
          rescue StandardError
            # Skip if can't get database name
          end

          lines << ''
          lines << '# This is an abstract class that establishes a database connection'
          lines << '# but does not have an associated table.'

          lines.join("\n")
        else
          # Add schema information for regular models (tables or views)
          adapter = Connection.adapter_for(model_class, conn)
          adapter.generate_annotation(model_class)
        end
      end
    end
  end
end
