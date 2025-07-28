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
      end
    end
  end
end
