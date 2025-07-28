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

      def process(model_class)
        if model_class.abstract_class?
          # For abstract classes, show database connection information in TOML format
          connection = model_class.connection
          adapter_name = connection.adapter_name

          lines = []
          lines << "database_dialect = \"#{adapter_name}\""

          # Add basic database information
          begin
            db_name = begin
              connection.database_version
            rescue StandardError
              'unknown'
            end
            lines << "database_version = \"#{db_name}\""
          rescue StandardError
            # Skip if can't get version
          end

          lines << ''
          lines << '# This is an abstract class that establishes a database connection'
          lines << '# but does not have an associated table.'

          lines.join("\n")
        else
          # Add schema information for regular models
          adapter = Connection.adapter_for(model_class)
          adapter.generate_annotation(model_class)
        end
      end
    end
  end
end
