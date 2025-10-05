# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Schema
    module Adapters
      class BaseTest < ActiveSupport::TestCase
        def setup
          # Use real connection (User model uses PostgreSQL primary database)
          @connection = User.connection
          @adapter = Base.new(@connection, 'users')
        end

        def test_initialize
          assert_equal @connection, @adapter.connection
          assert_equal 'users', @adapter.table_name
        end

        def test_adapter_name_delegation
          # Base adapter should delegate adapter_name to the connection
          assert_equal @connection.adapter_name, @adapter.adapter_name
        end

        def test_generate_annotation_basic_structure
          result = @adapter.generate_annotation(nil)

          assert_match(/table = "users"/, result)
          assert_match(/database_dialect/, result)
          assert_match(/columns = \[/, result)
        end

        def test_database_dialect
          dialect = @adapter.send(:database_dialect)

          assert_kind_of String, dialect
          assert_not_empty dialect
        end

        def test_unqualified_table_name_with_simple_name
          adapter = Base.new(@connection, 'users')

          assert_equal 'users', adapter.send(:unqualified_table_name)
        end

        def test_unqualified_table_name_with_schema_qualified_name
          adapter = Base.new(@connection, 'public.users')

          assert_equal 'users', adapter.send(:unqualified_table_name)
        end

        def test_unqualified_table_name_with_custom_schema
          adapter = Base.new(@connection, 'cms.posts')

          assert_equal 'posts', adapter.send(:unqualified_table_name)
        end

        def test_unqualified_table_name_caching
          adapter = Base.new(@connection, 'audit.events')

          # First call
          result1 = adapter.send(:unqualified_table_name)
          # Second call should use cached value
          result2 = adapter.send(:unqualified_table_name)

          assert_equal result1, result2
          assert_equal 'events', result1
        end

        def test_index_columns_array_handling
          # Test that Array() properly handles both string and array columns
          Base.new(@connection, 'users')

          # Create mock indexes with different column formats using Struct
          mock_index = Struct.new(:columns)
          string_columns_index = mock_index.new('email')
          array_columns_index = mock_index.new(%w[name email])

          # Verify both formats work with Array() wrapper
          assert_equal ['email'], Array(string_columns_index.columns)
          assert_equal %w[name email], Array(array_columns_index.columns)
        end
      end
    end
  end
end
