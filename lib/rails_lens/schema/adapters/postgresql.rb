# frozen_string_literal: true

module RailsLens
  module Schema
    module Adapters
      class Postgresql < Base
        def adapter_name
          'PostgreSQL'
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

          # Add schema information for PostgreSQL
          lines << "schema = \"#{schema_name}\"" if schema_name && schema_name != 'public'
          lines << ''

          add_columns_toml(lines)
          add_indexes_toml(lines) if show_indexes?
          add_foreign_keys_toml(lines) if show_foreign_keys?
          add_check_constraints_toml(lines) if show_check_constraints?
          add_table_comment_toml(lines) if show_comments?

          lines.join("\n")
        end

        def generate_view_annotation(model_class)
          lines = []
          lines << "view = \"#{table_name}\""
          lines << "database_dialect = \"#{database_dialect}\""

          # Add schema information for PostgreSQL
          lines << "schema = \"#{schema_name}\"" if schema_name && schema_name != 'public'

          # Fetch all view metadata in a single query
          view_info = fetch_view_metadata

          if view_info
            lines << "view_type = \"#{view_info[:type]}\"" if view_info[:type]
            lines << "updatable = #{view_info[:updatable]}"

            if view_info[:type] == 'materialized'
              lines << 'materialized = true'
              lines << 'refresh_strategy = "manual"'
            end
          end

          lines << ''

          add_columns_toml(lines)
          add_view_dependencies_toml(lines, view_info)

          lines.join("\n")
        end

        protected

        def schema_name
          @schema_name ||= if table_name.include?('.')
                             table_name.split('.').first
                           elsif connection.respond_to?(:current_schema)
                             connection.current_schema
                           end
        end

        def format_column(column)
          parts = []
          parts << column.name.ljust(column_name_width)

          # PostgreSQL specific type formatting
          type_string = format_column_type(column)
          parts << ":#{type_string.ljust(12)}"

          attributes = []
          attributes << 'not null' unless column.null
          attributes << 'primary key' if primary_key?(column)

          # Show sequence for serial columns
          if column.default&.match?(/nextval/)
            attributes << "default: nextval('#{extract_sequence_name(column.default)}')"
          elsif column.default && show_defaults?
            attributes << "default: #{format_default(column.default)}"
          end

          # Add column comment if available
          if show_comments? && (comment = column_comment(column.name))
            attributes << "comment: \"#{comment}\""
          end

          parts << attributes.join(', ') unless attributes.empty?

          " #{parts.join(' ')}"
        end

        def format_column_type(column)
          case column.type
          when :string
            column.limit ? "string(#{column.limit})" : 'string'
          when :decimal
            if column.precision && column.scale
              "decimal(#{column.precision},#{column.scale})"
            else
              'decimal'
            end
          when :integer
            case column.limit
            when 2 then 'smallint'
            when 8 then 'bigint'
            else 'integer'
            end
          else
            column.sql_type || column.type.to_s
          end
        end

        def extract_sequence_name(default_value)
          default_value.match(/nextval\('([^']+)'/)&.captures&.first || 'sequence'
        end

        def format_foreign_key(fk)
          base = " #{fk.name} (#{fk.column} => #{fk.to_table}.#{fk.primary_key})"

          # Add cascade options
          options = []
          options << "ON DELETE #{fk.on_delete.upcase}" if fk.on_delete
          options << "ON UPDATE #{fk.on_update.upcase}" if fk.on_update

          base += " #{options.join(' ')}" unless options.empty?
          base
        end

        def fetch_check_constraints
          return [] unless connection.supports_check_constraints?

          connection.check_constraints(table_name).map do |constraint|
            {
              name: constraint.name,
              expression: constraint.expression
            }
          end
        rescue ActiveRecord::StatementInvalid => e
          # Table doesn't exist or other database error
          Rails.logger.debug { "Failed to fetch check constraints for #{table_name}: #{e.message}" }
          []
        rescue PG::Error => e
          # PostgreSQL specific errors
          Rails.logger.debug { "PostgreSQL error fetching check constraints: #{e.message}" }
          []
        end

        def column_comment(column_name)
          return nil unless connection.respond_to?(:column_comment)

          connection.column_comment(table_name, column_name)
        rescue ActiveRecord::StatementInvalid => e
          # Table or column doesn't exist
          Rails.logger.debug { "Failed to fetch column comment for #{table_name}.#{column_name}: #{e.message}" }
          nil
        rescue PG::Error => e
          # PostgreSQL specific errors
          Rails.logger.debug { "PostgreSQL error fetching column comment: #{e.message}" }
          nil
        end

        def table_comment
          return nil unless connection.respond_to?(:table_comment)

          connection.table_comment(table_name)
        rescue ActiveRecord::StatementInvalid => e
          # Table doesn't exist
          Rails.logger.debug { "Failed to fetch table comment for #{table_name}: #{e.message}" }
          nil
        rescue PG::Error => e
          # PostgreSQL specific errors
          Rails.logger.debug { "PostgreSQL error fetching table comment: #{e.message}" }
          nil
        end

        def add_table_comment(lines)
          comment = table_comment
          return unless comment

          lines << '' unless lines.last && lines.last.empty?
          lines << 'Table Comment:'
          lines << " #{comment}"
        end

        def format_index(index)
          base = " #{index.name}"

          # Show column names
          columns = Array(index.columns).join(', ')
          base += " (#{columns})"

          # Index type
          attributes = []
          attributes << 'UNIQUE' if index.unique
          attributes << "USING #{index.using.upcase}" if index.respond_to?(:using) && index.using
          attributes << "WHERE #{index.where}" if index.respond_to?(:where) && index.where

          base += " #{attributes.join(' ')}" unless attributes.empty?
          base
        end

        def add_columns(lines)
          lines << 'Columns:'

          # Group columns by type for better readability
          columns.each do |column|
            lines << format_column(column)
          end
        end

        def add_table_comment_toml(lines)
          comment = table_comment
          return unless comment

          lines << ''
          lines << "table_comment = \"#{comment.gsub('"', '\"')}\""
        end

        def add_view_dependencies_toml(lines, view_info)
          return unless view_info && view_info[:dependencies]

          dependencies = view_info[:dependencies]
          return if dependencies.empty?

          lines << ''
          lines << "view_dependencies = [#{dependencies.map { |d| "\"#{d}\"" }.join(', ')}]"
        end

        # PostgreSQL-specific view methods
        public

        # Fetch all view metadata in a single consolidated query
        def fetch_view_metadata
          result = connection.exec_query(<<~SQL.squish, 'PostgreSQL View Metadata')
            WITH view_info AS (
              -- Check for materialized view
              SELECT
                'materialized' as view_type,
                false as is_updatable,
                mv.matviewname as view_name
              FROM pg_matviews mv
              WHERE mv.matviewname = '#{connection.quote_string(table_name)}'
              UNION ALL
              -- Check for regular view
              SELECT
                'regular' as view_type,
                CASE WHEN v.is_updatable = 'YES' THEN true ELSE false END as is_updatable,
                v.table_name as view_name
              FROM information_schema.views v
              WHERE v.table_name = '#{connection.quote_string(table_name)}'
            ),
            dependencies AS (
              SELECT DISTINCT c2.relname as dependency_name
              FROM pg_class c1
              JOIN pg_depend d ON c1.oid = d.objid
              JOIN pg_class c2 ON d.refobjid = c2.oid
              WHERE c1.relname = '#{connection.quote_string(table_name)}'
              AND c1.relkind IN ('v', 'm')
              AND c2.relkind IN ('r', 'v', 'm')
              AND d.deptype = 'n'
            )
            SELECT
              vi.view_type,
              vi.is_updatable,
              COALESCE(
                (SELECT array_agg(dependency_name ORDER BY dependency_name) FROM dependencies),
                ARRAY[]::text[]
              ) as dependencies
            FROM view_info vi
            LIMIT 1
          SQL

          return nil if result.rows.empty?

          row = result.rows.first
          {
            type: row[0],
            updatable: ['t', true].include?(row[1]),
            dependencies: row[2] || []
          }
        rescue ActiveRecord::StatementInvalid, PG::Error => e
          Rails.logger.debug { "Failed to fetch view metadata for #{table_name}: #{e.message}" }
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
          result = if view_type == 'materialized'
                     connection.exec_query(<<~SQL.squish, 'PostgreSQL Materialized View Definition')
                       SELECT definition FROM pg_matviews
                       WHERE matviewname = '#{connection.quote_string(table_name)}'
                       LIMIT 1
                     SQL
                   else
                     connection.exec_query(<<~SQL.squish, 'PostgreSQL View Definition')
                       SELECT view_definition FROM information_schema.views
                       WHERE table_name = '#{connection.quote_string(table_name)}'
                       LIMIT 1
                     SQL
                   end

          result.rows.first&.first&.strip
        rescue ActiveRecord::StatementInvalid, PG::Error
          nil
        end

        def view_refresh_strategy
          view_type == 'materialized' ? 'manual' : nil
        end

        def view_last_refreshed
          return nil unless view_type == 'materialized'

          # Get the last refresh time from pg_stat_user_tables
          result = connection.exec_query(<<~SQL.squish, 'PostgreSQL Materialized View Last Refresh')
            SELECT COALESCE(last_vacuum, last_autovacuum) as last_refreshed
            FROM pg_stat_user_tables
            WHERE relname = '#{connection.quote_string(table_name)}'
            LIMIT 1
          SQL

          result.rows.first&.first
        rescue ActiveRecord::StatementInvalid, PG::Error
          nil
        end
      end
    end
  end
end
