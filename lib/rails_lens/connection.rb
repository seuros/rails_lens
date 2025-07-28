# frozen_string_literal: true

module RailsLens
  class Connection
    class << self
      def adapter_for(model_class)
        connection = model_class.connection
        adapter_name = detect_adapter_name(connection)

        adapter_class = resolve_adapter_class(adapter_name)
        adapter_class.new(connection, model_class.table_name)
      end

      def resolve_adapter_class(adapter_name)
        class_name = "RailsLens::Schema::Adapters::#{adapter_name.to_s.camelize}"

        begin
          class_name.constantize
        rescue NameError
          raise RailsLens::UnsupportedAdapterError,
                "Unsupported database adapter: #{adapter_name}. " \
                "Expected adapter class #{class_name} not found. " \
                'Consider adding support by creating the adapter class.'
        end
      end

      def detect_adapter_name(connection)
        adapter_name = connection.adapter_name.downcase

        case adapter_name
        when /postgresql/, /postgis/
          :postgresql
        when /mysql2/, /trilogy/, /mariadb/
          :mysql
        when /sqlite/
          :sqlite3
        else
          # Return the normalized adapter name for constantize
          adapter_name.to_sym
        end
      end

      def database_dialect(connection)
        adapter_name = connection.adapter_name

        case adapter_name.downcase
        when /postgresql/, /postgis/
          'PostgreSQL'
        when /mysql2/, /trilogy/
          'MySQL'
        when /mariadb/
          'MariaDB'
        when /sqlite/
          'SQLite'
        else
          adapter_name # Return the original adapter name if unknown
        end
      end

      def connection_config(model_class)
        if model_class.connection.respond_to?(:connection_db_config)
          # Rails 6.1+
          model_class.connection.connection_db_config.configuration_hash
        elsif model_class.connection.respond_to?(:config)
          # Older Rails versions
          model_class.connection.config
        else
          {}
        end
      end

      def database_version(model_class)
        connection = model_class.connection

        if connection.respond_to?(:database_version)
          connection.database_version
        elsif connection.respond_to?(:version)
          connection.version
        else
          'Unknown'
        end
      rescue StandardError
        'Unknown'
      end

      def connection_info(model_class)
        {
          adapter: detect_adapter_name(model_class.connection),
          database: connection_config(model_class)[:database],
          version: database_version(model_class),
          encoding: connection_encoding(model_class)
        }
      end

      def supports_foreign_keys?(model_class)
        model_class.connection.supports_foreign_keys?
      end

      def supports_check_constraints?(model_class)
        model_class.connection.supports_check_constraints?
      end

      def supports_comments?(model_class)
        model_class.connection.supports_comments?
      end

      def supports_views?(model_class)
        model_class.connection.supports_views?
      end

      def supports_materialized_views?(model_class)
        model_class.connection.supports_materialized_views?
      end

      private

      def connection_encoding(model_class)
        connection = model_class.connection

        if connection.respond_to?(:encoding)
          connection.encoding
        elsif connection.respond_to?(:charset)
          connection.charset
        else
          config = connection_config(model_class)
          config[:encoding] || config[:charset] || 'Unknown'
        end
      rescue StandardError
        'Unknown'
      end
    end
  end
end
