# frozen_string_literal: true

module RailsLens
  module Schema
    module Adapters
      class Sqlite3 < Base
        def adapter_name
          'SQLite'
        end

        def generate_annotation(_model_class)
          lines = []
          lines << "table = \"#{table_name}\""
          lines << "database_dialect = \"#{database_dialect}\""
          lines << ''

          add_columns_toml(lines)
          add_indexes_toml(lines) if show_indexes?
          add_foreign_keys_toml(lines) if show_foreign_keys?
          add_sqlite_pragmas_toml(lines)

          lines.join("\n")
        end

        protected

        def format_column(column)
          parts = []
          parts << column.name.ljust(column_name_width)
          parts << ":#{column.type.to_s.ljust(12)}"

          attributes = []
          attributes << 'not null' unless column.null
          attributes << 'primary key' if primary_key?(column)

          # SQLite3 specific: show auto-increment info
          attributes << 'autoincrement' if primary_key?(column) && column.type == :integer

          attributes << "default: #{format_default(column.default)}" if column.default && show_defaults?

          parts << attributes.join(', ') unless attributes.empty?

          " #{parts.join(' ')}"
        end

        def fetch_indexes
          # SQLite3 returns different index info, filter out auto-generated ones
          super.reject { |index| index.name =~ /^sqlite_autoindex/ }
        end

        def fetch_check_constraints
          # SQLite3 stores check constraints in table info
          # This would require raw SQL queries to extract
          []
        end

        def add_sqlite_pragmas_structured(lines)
          # Add SQLite-specific information if needed
          return unless connection.respond_to?(:execute)

          begin
            # Example: Foreign keys status
            fk_status = connection.execute('PRAGMA foreign_keys').first
            lines << 'FOREIGN_KEYS_ENABLED: false' if fk_status && fk_status['foreign_keys'].zero?
          rescue ActiveRecord::StatementInvalid => e
            # SQLite doesn't recognize the pragma or access denied
            Rails.logger.debug { "Failed to fetch SQLite foreign_keys pragma: #{e.message}" }
          rescue SQLite3::Exception => e
            # SQLite specific errors (database locked, etc)
            Rails.logger.debug { "SQLite error fetching pragmas: #{e.message}" }
          end
        end

        def add_sqlite_pragmas_toml(lines)
          # Add SQLite-specific information if needed
          return unless connection.respond_to?(:execute)

          begin
            # Example: Foreign keys status
            fk_status = connection.execute('PRAGMA foreign_keys').first
            if fk_status && fk_status['foreign_keys'].zero?
              lines << ''
              lines << 'foreign_keys_enabled = false'
            end
          rescue ActiveRecord::StatementInvalid => e
            # SQLite doesn't recognize the pragma or access denied
            Rails.logger.debug { "Failed to fetch SQLite foreign_keys pragma: #{e.message}" }
          rescue SQLite3::Exception => e
            # SQLite specific errors (database locked, etc)
            Rails.logger.debug { "SQLite error fetching pragmas: #{e.message}" }
          end
        end
      end
    end
  end
end
