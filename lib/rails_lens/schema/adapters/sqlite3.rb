# frozen_string_literal: true

module RailsLens
  module Schema
    module Adapters
      class Sqlite3 < Base
        def adapter_name
          'SQLite'
        end

        def generate_annotation(model_class)
          if model_class && ModelDetector.view_exists?(model_class)
            generate_view_annotation(model_class)
          else
            generate_table_annotation(model_class)
          end
        end

        def generate_table_annotation(_model_class)
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

        def generate_view_annotation(model_class)
          lines = []
          lines << "view = \"#{table_name}\""
          lines << "database_dialect = \"#{database_dialect}\""

          # Fetch all view metadata in a single query
          view_info = fetch_view_metadata

          if view_info
            lines << "view_type = \"#{view_info[:type]}\"" if view_info[:type]
            lines << "updatable = #{view_info[:updatable]}"
          end

          lines << ''

          add_columns_toml(lines)
          add_view_dependencies_toml(lines, view_info)

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
            RailsLens.logger.debug { "Failed to fetch SQLite foreign_keys pragma: #{e.message}" }
          rescue SQLite3::Exception => e
            # SQLite specific errors (database locked, etc)
            RailsLens.logger.debug { "SQLite error fetching pragmas: #{e.message}" }
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
            RailsLens.logger.debug { "Failed to fetch SQLite foreign_keys pragma: #{e.message}" }
          rescue SQLite3::Exception => e
            # SQLite specific errors (database locked, etc)
            RailsLens.logger.debug { "SQLite error fetching pragmas: #{e.message}" }
          end
        end

        def add_view_dependencies_toml(lines, view_info)
          return unless view_info && view_info[:dependencies]

          dependencies = view_info[:dependencies]
          return if dependencies.empty?

          lines << ''
          lines << "view_dependencies = [#{dependencies.map { |d| "\"#{d}\"" }.join(', ')}]"
        end

        # SQLite-specific view methods
        public

        # Fetch all view metadata in a single consolidated query
        def fetch_view_metadata
          result = connection.exec_query(<<~SQL.squish, 'SQLite View Metadata')
            SELECT sql FROM sqlite_master
            WHERE type = 'view' AND name = '#{connection.quote_string(table_name)}'
            LIMIT 1
          SQL

          return nil if result.rows.empty?

          definition = result.rows.first&.first&.strip
          return nil unless definition

          # Parse dependencies from the SQL definition
          tables = []
          definition.scan(/(?:FROM|JOIN)\s+(\w+)/i) do |match|
            table_name_match = match[0]
            # Exclude the view itself and common SQL keywords
            if !table_name_match.downcase.in?(%w[select where order group having limit offset]) &&
               tables.exclude?(table_name_match) &&
               table_name_match != table_name
              tables << table_name_match
            end
          end

          {
            type: 'regular',  # SQLite only supports regular views
            updatable: false, # SQLite views are generally read-only
            dependencies: tables.sort
          }
        rescue ActiveRecord::StatementInvalid, SQLite3::Exception => e
          RailsLens.logger.debug { "Failed to fetch view metadata for #{table_name}: #{e.message}" }
          nil
        end

        # Legacy methods - kept for backward compatibility but now use consolidated query
        def view_type
          @view_metadata ||= fetch_view_metadata
          @view_metadata&.dig(:type)
        end

        def view_updatable?
          @view_metadata ||= fetch_view_metadata
          @view_metadata&.dig(:updatable) || false
        end

        def view_dependencies
          @view_metadata ||= fetch_view_metadata
          @view_metadata&.dig(:dependencies) || []
        end

        def view_definition
          result = connection.exec_query(<<~SQL.squish, 'SQLite View Definition')
            SELECT sql FROM sqlite_master
            WHERE type = 'view' AND name = '#{connection.quote_string(table_name)}'
            LIMIT 1
          SQL

          result.rows.first&.first&.strip
        rescue ActiveRecord::StatementInvalid, SQLite3::Exception
          nil
        end

        def view_refresh_strategy
          nil # SQLite doesn't have materialized views
        end

        def view_last_refreshed
          nil # SQLite doesn't have materialized views
        end
      end
    end
  end
end
