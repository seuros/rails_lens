# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Schema
    module Adapters
      class Sqlite3Test < ActiveSupport::TestCase
        def setup
          # Use real SQLite connection from Family model (prehistoric database)
          @connection = Family.connection
          @adapter = Sqlite3.new(@connection, 'families')
        end

        def test_adapter_name
          assert_equal 'SQLite', @adapter.adapter_name
        end

        def test_generate_annotation_basic
          result = @adapter.generate_annotation(nil)

          assert_match(/table = "families"/, result)
          assert_match(/database_dialect = "SQLite"/, result)
          assert_match(/columns = \[/, result)
        end

        def test_generate_annotation_includes_columns
          result = @adapter.generate_annotation(nil)

          # Should include actual Family table columns
          assert_match(/"id"/, result)
          assert_match(/"name"/, result)
          assert_match(/"parent_id"/, result)
          assert_match(/"classification"/, result)
        end

        def test_sqlite_specific_dialect
          dialect = @adapter.send(:database_dialect)

          assert_equal 'SQLite', dialect
        end

        def test_sqlite_specific_features
          # Test SQLite-specific behavior
          assert_equal 'SQLite', @adapter.adapter_name
          assert_includes @connection.adapter_name.downcase, 'sqlite'
        end
      end
    end
  end
end
