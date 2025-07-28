# frozen_string_literal: true

module RailsLens
  module Schema
    module Adapters
      class Mysql < Base
        def adapter_name
          'MySQL'
        end

        def generate_annotation(_model_class)
          lines = []
          lines << "table = \"#{table_name}\""
          lines << "database_dialect = \"#{database_dialect}\""

          # Add storage engine information
          if (engine = table_storage_engine)
            lines << "storage_engine = \"#{engine}\""
          end

          # Add character set and collation
          if (charset = table_charset)
            lines << "character_set = \"#{charset}\""
          end

          if (collation = table_collation)
            lines << "collation = \"#{collation}\""
          end

          lines << ''

          add_columns_toml(lines)
          add_indexes_toml(lines) if show_indexes?
          add_foreign_keys_toml(lines) if show_foreign_keys?
          add_partitions_toml(lines) if has_partitions?

          lines.join("\n")
        end

        protected

        def format_column(column)
          parts = []
          parts << column.name.ljust(column_name_width)

          # MySQL specific type formatting
          type_string = format_column_type(column)
          parts << ":#{type_string.ljust(12)}"

          attributes = []
          attributes << 'not null' unless column.null
          attributes << 'primary key' if primary_key?(column)

          # MySQL specific: show auto_increment
          attributes << 'auto_increment' if primary_key?(column) && column.extra == 'auto_increment'

          # Show character set and collation for string columns
          if %i[string text].include?(column.type) && column.respond_to?(:charset)
            attributes << "charset: #{column.charset}" if column.charset
            attributes << "collation: #{column.collation}" if column.collation
          end

          attributes << "default: #{format_default(column.default)}" if column.default && show_defaults?

          # Add column comment if available
          if show_comments? && column.respond_to?(:comment) && column.comment
            attributes << "comment: \"#{column.comment}\""
          end

          parts << attributes.join(', ') unless attributes.empty?

          " #{parts.join(' ')}"
        end

        def format_column_type(column)
          case column.type
          when :string
            column.limit ? "varchar(#{column.limit})" : 'varchar'
          when :text
            case column.limit
            when 0..255 then 'tinytext'
            when 256..65_535 then 'text'
            when 65_536..16_777_215 then 'mediumtext'
            else 'longtext'
            end
          when :binary
            case column.limit
            when 0..255 then 'tinyblob'
            when 256..65_535 then 'blob'
            when 65_536..16_777_215 then 'mediumblob'
            else 'longblob'
            end
          when :integer
            # MySQL integer types
            case column.limit
            when 1 then 'tinyint'
            when 2 then 'smallint'
            when 3 then 'mediumint'
            when 8 then 'bigint'
            else 'int'
            end
          else
            column.sql_type || column.type.to_s
          end
        end

        def table_storage_engine
          result = connection.execute("SHOW TABLE STATUS LIKE '#{table_name}'").first
          return nil unless result

          # Handle both hash and array results from different MySQL adapters
          if result.is_a?(Hash)
            result['Engine']
          elsif result.is_a?(Array)
            result[1] # Engine is typically the second column
          end
        rescue ActiveRecord::StatementInvalid => e
          Rails.logger.debug { "Failed to fetch storage engine for #{table_name}: #{e.message}" }
          nil
        rescue Mysql2::Error => e
          Rails.logger.debug { "MySQL error fetching storage engine: #{e.message}" }
          nil
        end

        def table_charset
          result = connection.execute("SHOW TABLE STATUS LIKE '#{table_name}'").first
          return nil unless result

          # Handle both hash and array results from different MySQL adapters
          collation = if result.is_a?(Hash)
                        result['Collation']
                      elsif result.is_a?(Array)
                        result[14] # Collation is typically the 15th column
                      end

          collation&.split('_')&.first
        rescue ActiveRecord::StatementInvalid => e
          Rails.logger.debug { "Failed to fetch charset for #{table_name}: #{e.message}" }
          nil
        rescue Mysql2::Error => e
          Rails.logger.debug { "MySQL error fetching charset: #{e.message}" }
          nil
        end

        def table_collation
          result = connection.execute("SHOW TABLE STATUS LIKE '#{table_name}'").first
          return nil unless result

          # Handle both hash and array results from different MySQL adapters
          if result.is_a?(Hash)
            result['Collation']
          elsif result.is_a?(Array)
            result[14] # Collation is typically the 15th column
          end
        rescue ActiveRecord::StatementInvalid => e
          Rails.logger.debug { "Failed to fetch collation for #{table_name}: #{e.message}" }
          nil
        rescue Mysql2::Error => e
          Rails.logger.debug { "MySQL error fetching collation: #{e.message}" }
          nil
        end

        def format_index(index)
          base = " #{index.name}"

          columns = Array(index.columns).join(', ')
          base += " (#{columns})"

          attributes = []
          attributes << 'UNIQUE' if index.unique
          attributes << 'FULLTEXT' if index.type == 'FULLTEXT'
          attributes << 'SPATIAL' if index.type == 'SPATIAL'

          # Show index type (BTREE, HASH)
          attributes << "USING #{index.using}" if index.respond_to?(:using) && index.using

          base += " #{attributes.join(' ')}" unless attributes.empty?
          base
        end

        def has_partitions?
          return false unless connection.respond_to?(:execute)

          result = connection.execute(<<-SQL.squish)
          SELECT COUNT(*) as count
          FROM information_schema.partitions
          WHERE table_schema = DATABASE()
            AND table_name = '#{table_name}'
            AND partition_name IS NOT NULL
          SQL

          count = if result.first.is_a?(Hash)
                    result.first['count'] || result.first[:count]
                  elsif result.first.is_a?(Array)
                    result.first[0] # count is the first column
                  else
                    0
                  end

          count.to_i.positive?
        rescue ActiveRecord::StatementInvalid => e
          # Table doesn't exist or no permission to query information_schema
          Rails.logger.debug { "Failed to check partitions for #{table_name}: #{e.message}" }
          false
        rescue Mysql2::Error => e
          # MySQL specific errors (connection issues, etc)
          Rails.logger.debug { "MySQL error checking partitions: #{e.message}" }
          false
        end

        def add_partitions(lines)
          return unless connection.respond_to?(:execute)

          partitions = connection.execute(<<-SQL.squish)
          SELECT partition_name, partition_expression, partition_description
          FROM information_schema.partitions
          WHERE table_schema = DATABASE()
            AND table_name = '#{table_name}'
            AND partition_name IS NOT NULL
          ORDER BY partition_ordinal_position
          SQL

          return if partitions.none?

          lines << '' unless lines.last && lines.last.empty?
          lines << 'Partitions:'

          partitions.each do |partition|
            lines << " #{partition['partition_name']}: #{partition['partition_description']}"
          end
        rescue ActiveRecord::StatementInvalid => e
          # Permission denied or table doesn't exist
          Rails.logger.debug { "Failed to fetch partitions for #{table_name}: #{e.message}" }
        rescue Mysql2::Error => e
          # MySQL specific errors
          Rails.logger.debug { "MySQL error fetching partitions: #{e.message}" }
        end

        def add_partitions_toml(lines)
          return unless connection.respond_to?(:execute)

          partitions = connection.execute(<<-SQL.squish)
          SELECT partition_name, partition_expression, partition_description
          FROM information_schema.partitions
          WHERE table_schema = DATABASE()
            AND table_name = '#{table_name}'
            AND partition_name IS NOT NULL
          ORDER BY partition_ordinal_position
          SQL

          return if partitions.none?

          lines << ''
          lines << 'partitions = ['

          partitions.each_with_index do |partition, i|
            line = '  { '
            attrs = []
            attrs << "name = \"#{partition['partition_name']}\""
            attrs << "description = \"#{partition['partition_description']}\""
            attrs << "expression = \"#{partition['partition_expression']}\"" if partition['partition_expression']
            line += attrs.join(', ')
            line += ' }'
            line += ',' if i < partitions.count - 1
            lines << line
          end

          lines << ']'
        rescue ActiveRecord::StatementInvalid => e
          # Permission denied or table doesn't exist
          Rails.logger.debug { "Failed to fetch partitions for #{table_name}: #{e.message}" }
        rescue Mysql2::Error => e
          # MySQL specific errors
          Rails.logger.debug { "MySQL error fetching partitions: #{e.message}" }
        end
      end
    end
  end
end
