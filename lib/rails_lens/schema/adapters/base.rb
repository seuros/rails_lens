# frozen_string_literal: true

module RailsLens
  module Schema
    module Adapters
      class Base
        attr_reader :connection, :table_name

        def initialize(connection, table_name)
          @connection = connection
          @table_name = table_name
        end

        # Extract table name without schema prefix for ActiveRecord connection methods
        # PostgreSQL tables can be schema-qualified (e.g., "cms.posts")
        def unqualified_table_name
          @unqualified_table_name ||= table_name.to_s.split('.').last
        end

        def generate_annotation(_model_class)
          lines = []
          lines << "table = \"#{table_name}\""
          lines << "database_dialect = \"#{database_dialect}\""
          lines << ''

          add_columns_toml(lines)
          add_indexes_toml(lines) if show_indexes?
          add_foreign_keys_toml(lines) if show_foreign_keys?
          add_check_constraints_toml(lines) if show_check_constraints?

          lines.join("\n")
        end

        delegate :adapter_name, to: :connection

        protected

        def database_dialect
          RailsLens::Connection.database_dialect(connection)
        end

        def add_columns(lines)
          lines << 'Columns:'
          columns.each do |column|
            lines << format_column(column)
          end
        end

        def add_indexes(lines)
          indexes = fetch_indexes
          return if indexes.empty?

          lines << '' unless lines.last && lines.last.empty?
          lines << 'Indexes:'
          indexes.each do |index|
            lines << format_index(index)
          end
        end

        def add_foreign_keys(lines)
          foreign_keys = fetch_foreign_keys
          return if foreign_keys.empty?

          lines << '' unless lines.last && lines.last.empty?
          lines << 'Foreign Keys:'
          foreign_keys.each do |fk|
            lines << format_foreign_key(fk)
          end
        end

        def add_check_constraints(lines)
          constraints = fetch_check_constraints
          return if constraints.empty?

          lines << '' unless lines.last && lines.last.empty?
          lines << 'Check Constraints:'
          constraints.each do |constraint|
            lines << format_check_constraint(constraint)
          end
        end

        def columns
          @columns ||= connection.columns(unqualified_table_name)
        end

        def fetch_indexes
          connection.indexes(unqualified_table_name)
        end

        def fetch_foreign_keys
          if connection.supports_foreign_keys?
            connection.foreign_keys(unqualified_table_name)
          else
            []
          end
        end

        def fetch_check_constraints
          # Override in database-specific adapters
          []
        end

        def format_column(column)
          parts = []
          parts << column.name.ljust(column_name_width)
          parts << ":#{column.type.to_s.ljust(12)}"

          attributes = []
          attributes << 'not null' unless column.null
          attributes << 'primary key' if primary_key?(column)
          attributes << "default: #{format_default(column.default)}" if column.default && show_defaults?

          parts << attributes.join(', ') unless attributes.empty?

          " #{parts.join(' ')}"
        end

        def format_index(index)
          unique = index.unique ? ' UNIQUE' : ''
          columns = Array(index.columns).join(', ')
          " #{index.name} (#{columns})#{unique}"
        end

        def format_foreign_key(fk)
          " #{fk.name} (#{fk.column} => #{fk.to_table}.#{fk.primary_key})"
        end

        def format_check_constraint(constraint)
          " #{constraint[:name]}: #{constraint[:expression]}"
        end

        def format_default(default)
          case default
          when String
            %("#{default}")
          when NilClass
            'nil'
          else
            default.inspect
          end
        end

        def primary_key?(column)
          column.name == primary_key_name
        end

        def primary_key_name
          @primary_key_name ||= connection.primary_key(unqualified_table_name)
        end

        def column_name_width
          @column_name_width ||= columns.map { |c| c.name.length }.max || 0
        end

        def show_indexes?
          RailsLens.config.schema[:format_options][:show_indexes]
        end

        def show_foreign_keys?
          RailsLens.config.schema[:format_options][:show_foreign_keys] &&
            connection.supports_foreign_keys?
        end

        def show_check_constraints?
          RailsLens.config.schema[:format_options][:show_check_constraints] &&
            connection.supports_check_constraints?
        end

        def show_defaults?
          RailsLens.config.schema[:format_options][:show_defaults]
        end

        def show_comments?
          RailsLens.config.schema[:format_options][:show_comments] &&
            connection.supports_comments?
        end

        # Structured formatting methods
        def add_columns_structured(lines)
          lines << 'COLUMNS:'
          columns.each do |column|
            lines << format_column_structured(column)
          end
        end

        def add_indexes_structured(lines)
          indexes = fetch_indexes
          return if indexes.empty?

          lines << 'INDEXES:'
          indexes.each do |index|
            lines << format_index_structured(index)
          end
        end

        def add_foreign_keys_structured(lines)
          foreign_keys = fetch_foreign_keys
          return if foreign_keys.empty?

          lines << 'FOREIGN_KEYS:'
          foreign_keys.each do |fk|
            lines << format_foreign_key_structured(fk)
          end
        end

        def add_check_constraints_structured(lines)
          constraints = fetch_check_constraints
          return if constraints.empty?

          lines << 'CHECK_CONSTRAINTS:'
          constraints.each do |constraint|
            lines << format_check_constraint_structured(constraint)
          end
        end

        def format_column_structured(column)
          attributes = []
          attributes << column.type.to_s
          attributes << 'primary_key' if column.name == 'id' || (column.name.end_with?('_id') && column.type == :bigint)
          attributes << (column.null ? 'nullable' : 'not_null')
          attributes << "default: #{column.default}" if column.default && show_defaults?

          "  #{column.name}: #{attributes.join(', ')}"
        end

        def format_index_structured(index)
          attributes = []
          attributes << "columns: [#{index.columns.join(', ')}]"
          attributes << 'unique' if index.unique
          attributes << "type: #{index.type}" if index.respond_to?(:type) && index.type

          "  #{index.name}: #{attributes.join(', ')}"
        end

        def format_foreign_key_structured(fk)
          "  #{fk.column}: references #{fk.to_table}(#{fk.primary_key})"
        end

        def format_check_constraint_structured(constraint)
          if constraint.is_a?(Hash)
            "  #{constraint[:name]}: #{constraint[:expression]}"
          else
            "  #{constraint.name}: #{constraint.expression}"
          end
        end

        # TOML formatting methods
        def add_columns_toml(lines)
          lines << 'columns = ['
          columns.each_with_index do |column, index|
            line = '  { '
            attrs = []
            attrs << "name = \"#{column.name}\""
            attrs << "type = \"#{column.type}\""
            attrs << 'primary_key = true' if primary_key?(column)
            attrs << "nullable = #{column.null}"
            attrs << "default = #{format_toml_value(column.default)}" if column.default && show_defaults?
            line += attrs.join(', ')
            line += ' }'
            line += ',' if index < columns.length - 1
            lines << line
          end
          lines << ']'
        end

        def add_indexes_toml(lines)
          indexes = fetch_indexes
          return if indexes.empty?

          lines << ''
          lines << 'indexes = ['
          indexes.each_with_index do |index, i|
            line = '  { '
            attrs = []
            attrs << "name = \"#{index.name}\""
            attrs << "columns = [#{Array(index.columns).map { |c| "\"#{c}\"" }.join(', ')}]"
            attrs << 'unique = true' if index.unique
            attrs << "type = \"#{index.type}\"" if index.respond_to?(:type) && index.type
            line += attrs.join(', ')
            line += ' }'
            line += ',' if i < indexes.length - 1
            lines << line
          end
          lines << ']'
        end

        def add_foreign_keys_toml(lines)
          foreign_keys = fetch_foreign_keys
          return if foreign_keys.empty?

          lines << ''
          lines << 'foreign_keys = ['
          foreign_keys.each_with_index do |fk, i|
            line = '  { '
            attrs = []
            attrs << "column = \"#{fk.column}\""
            attrs << "references_table = \"#{fk.to_table}\""
            attrs << "references_column = \"#{fk.primary_key}\""
            attrs << "name = \"#{fk.name}\"" if fk.respond_to?(:name) && fk.name
            attrs << "on_delete = \"#{fk.on_delete}\"" if fk.respond_to?(:on_delete) && fk.on_delete
            attrs << "on_update = \"#{fk.on_update}\"" if fk.respond_to?(:on_update) && fk.on_update
            line += attrs.join(', ')
            line += ' }'
            line += ',' if i < foreign_keys.length - 1
            lines << line
          end
          lines << ']'
        end

        def add_check_constraints_toml(lines)
          constraints = fetch_check_constraints
          return if constraints.empty?

          lines << ''
          lines << 'check_constraints = ['
          constraints.each_with_index do |constraint, i|
            line = '  { '
            attrs = []
            if constraint.is_a?(Hash)
              attrs << "name = \"#{constraint[:name]}\""
              attrs << "expression = \"#{constraint[:expression]}\""
            else
              attrs << "name = \"#{constraint.name}\""
              attrs << "expression = \"#{constraint.expression}\""
            end
            line += attrs.join(', ')
            line += ' }'
            line += ',' if i < constraints.length - 1
            lines << line
          end
          lines << ']'
        end

        def format_toml_value(value)
          case value
          when String
            "\"#{value.gsub('"', '\"')}\""
          when NilClass
            'null'
          when TrueClass, FalseClass
            value.to_s
          when Numeric
            value.to_s
          else
            "\"#{value}\""
          end
        end
      end
    end
  end
end
