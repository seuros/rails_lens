# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Schema
    module Adapters
      class MysqlTest < ActiveSupport::TestCase
        def setup
          # Use real MySQL connection from Vehicle model (vehicles database)
          @connection = Vehicle.connection
          @adapter = Mysql.new(@connection, 'vehicles')
        end

        def test_adapter_name
          assert_equal 'MySQL', @adapter.adapter_name
        end

        def test_generate_annotation_basic
          result = @adapter.generate_annotation(nil)

          assert_match(/table = "vehicles"/, result)
          assert_match(/database_dialect = "MySQL"/, result)
          assert_match(/columns = \[/, result)
        end

        def test_generate_annotation_includes_columns
          result = @adapter.generate_annotation(nil)

          # Should include actual Vehicle table columns
          assert_match(/"id"/, result)
          assert_match(/"name"/, result)
          assert_match(/"model"/, result)
          assert_match(/"year"/, result)
          assert_match(/"price"/, result)
        end

        def test_generate_annotation_includes_mysql_specifics
          result = @adapter.generate_annotation(nil)

          # Should include MySQL-specific information
          assert_match(/storage_engine/, result)
          assert_match(/character_set/, result)
          assert_match(/collation/, result)
        end

        def test_mysql_specific_dialect
          dialect = @adapter.send(:database_dialect)

          assert_equal 'MySQL', dialect
        end

        def test_mysql_specific_features
          # Test MySQL-specific behavior
          assert_equal 'MySQL', @adapter.adapter_name
          assert_includes @connection.adapter_name.downcase, 'mysql'
        end
      end
    end
  end
end
