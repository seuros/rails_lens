# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Schema
    module Adapters
      class PostgresqlTest < ActiveSupport::TestCase
        def setup
          # Use real PostgreSQL connection from User model
          @connection = User.connection
          @adapter = Postgresql.new(@connection, 'users')
        end

        def test_adapter_name
          assert_equal 'PostgreSQL', @adapter.adapter_name
        end

        def test_generate_annotation_basic
          result = @adapter.generate_annotation(nil)

          assert_match(/table = "users"/, result)
          assert_match(/database_dialect = "PostgreSQL"/, result)
          assert_match(/columns = \[/, result)
        end

        def test_generate_annotation_includes_columns
          result = @adapter.generate_annotation(nil)

          # Should include actual User table columns
          assert_match(/"id"/, result)
          assert_match(/"email"/, result)
          assert_match(/"name"/, result)
        end

        def test_postgresql_specific_dialect
          dialect = @adapter.send(:database_dialect)

          assert_equal 'PostgreSQL', dialect
        end

        def test_schema_qualified_table_name_extraction
          adapter = Postgresql.new(@connection, 'audit.test_table')

          # Test unqualified_table_name helper extracts correctly
          assert_equal 'test_table', adapter.send(:unqualified_table_name)

          # Test schema_name extraction
          assert_equal 'audit', adapter.send(:schema_name)
        end

        def test_schema_qualified_table_name_in_annotation
          # Use existing AuditLog model with schema-qualified table name
          adapter = Postgresql.new(@connection, 'audit.audit_logs')
          annotation = adapter.generate_annotation(AuditLog)

          # Verify schema-qualified table name is preserved
          assert_includes annotation, 'table = "audit.audit_logs"'
          assert_includes annotation, 'schema = "audit"'

          # Verify columns were extracted successfully
          assert_includes annotation, 'columns = ['
          assert_includes annotation, 'name = "id"'
          assert_includes annotation, 'name = "table_name"'
          assert_includes annotation, 'name = "record_id"'
        end

        def test_schema_search_path_handling
          # Create test table in custom schema
          @connection.execute('CREATE SCHEMA IF NOT EXISTS custom_schema')
          @connection.execute(<<~SQL.squish)
            CREATE TABLE IF NOT EXISTS custom_schema.widgets (
              id serial PRIMARY KEY,
              name varchar(100) NOT NULL
            )
          SQL

          adapter = Postgresql.new(@connection, 'custom_schema.widgets')

          # These operations should work without errors
          assert_nothing_raised do
            columns = adapter.send(:columns)

            assert_predicate columns, :any?
            assert(columns.any? { |c| c.name == 'id' })
            assert(columns.any? { |c| c.name == 'name' })
          end

          # Verify primary_key extraction works
          assert_nothing_raised do
            pk = adapter.send(:primary_key_name)

            assert_equal 'id', pk
          end
        ensure
          begin
            @connection.execute('DROP TABLE IF EXISTS custom_schema.widgets')
          rescue
            nil
          end
          begin
            @connection.execute('DROP SCHEMA IF EXISTS custom_schema CASCADE')
          rescue
            nil
          end
        end
      end
    end
  end
end
