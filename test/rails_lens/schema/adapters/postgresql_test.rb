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
      end
    end
  end
end
