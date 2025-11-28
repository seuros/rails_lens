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
          # Use existing audit schema table
          adapter = Postgresql.new(@connection, 'audit.audit_logs')

          # These operations should work without errors
          assert_nothing_raised do
            columns = adapter.send(:columns)

            assert_predicate columns, :any?
            assert(columns.any? { |c| c.name == 'id' })
            assert(columns.any? { |c| c.name == 'table_name' })
            assert(columns.any? { |c| c.name == 'record_id' })
          end

          # Verify primary_key extraction works
          assert_nothing_raised do
            pk = adapter.send(:primary_key_name)

            assert_equal 'id', pk
          end
        end

        def test_fetch_triggers_returns_user_defined_triggers
          # Use existing comments table which has triggers defined in schema.rb
          adapter = Postgresql.new(@connection, 'comments')
          triggers = adapter.fetch_triggers

          assert_predicate triggers, :any?, 'Expected at least one trigger'

          trigger = triggers.find { |t| t[:name] == 'increment_posts_comments_count' }

          assert trigger, 'Expected to find increment_posts_comments_count'
          assert_equal 'AFTER', trigger[:timing]
          assert_equal 'INSERT', trigger[:event]
          assert_equal 'ROW', trigger[:for_each]
          assert_equal 'update_posts_comments_count', trigger[:function]
        end

        def test_fetch_triggers_excludes_extension_triggers
          adapter = Postgresql.new(@connection, 'users')
          triggers = adapter.fetch_triggers

          # Extension triggers (if any) should be excluded
          # This mainly tests the query doesn't error
          assert_instance_of Array, triggers
        end

        def test_fetch_triggers_with_when_condition
          # Use existing comments table - triggers have WHEN conditions
          adapter = Postgresql.new(@connection, 'comments')
          triggers = adapter.fetch_triggers

          trigger = triggers.find { |t| t[:name] == 'increment_posts_comments_count' }

          assert trigger, 'Expected to find increment_posts_comments_count'
          assert_match(/post_id/, trigger[:condition].to_s)
        end

        def test_triggers_included_in_annotation
          # Use existing comments table with triggers
          adapter = Postgresql.new(@connection, 'comments')
          annotation = adapter.generate_annotation(nil)

          assert_match(/triggers = \[/, annotation)
          assert_match(/increment_posts_comments_count/, annotation)
          assert_match(/timing = "AFTER"/, annotation)
          assert_match(/event = "INSERT"/, annotation)
        end
      end
    end
  end
end
