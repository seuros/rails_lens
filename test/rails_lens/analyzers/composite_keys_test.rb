# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Analyzers
    class CompositeKeysTest < ActiveSupport::TestCase
      def test_analyze_with_normal_single_primary_key_models
        # Test with real models that have single primary keys
        [User, Post, Vehicle, Family].each do |model|
          analyzer = CompositeKeys.new(model)
          result = analyzer.analyze

          # Single primary key models should return nil (no composite key info)
          assert_nil result, "#{model.name} should not have composite key info"
        end
      end

      def test_analyze_with_real_composite_primary_key_model
        # OrderLineItem has real composite primary key [:order_id, :line_number]
        analyzer = CompositeKeys.new(OrderLineItem)
        result = analyzer.analyze

        assert_match(/== Composite Primary Key/, result)
        assert_match(/Primary Keys: order_id, line_number/, result)
      end

      def test_analyze_respects_actual_model_primary_key_behavior
        # Verify that the analyzer works with real model primary key behavior

        # Real single-key models should have single primary keys
        assert_equal 'id', User.primary_key
        assert_equal 'id', Vehicle.primary_key
        assert_equal 'id', Family.primary_key

        # OrderLineItem should have composite primary key
        assert_equal %w[order_id line_number], OrderLineItem.primary_key

        # Single-key models should not support primary_keys method
        assert_not User.respond_to?(:primary_keys)
        assert_not Vehicle.respond_to?(:primary_keys)
        assert_not Family.respond_to?(:primary_keys)

        # OrderLineItem should support primary_keys method
        assert_respond_to OrderLineItem, :primary_keys
        assert_equal %w[order_id line_number], OrderLineItem.primary_keys

        # So analyzer should return nil for single-key models
        [User, Vehicle, Family].each do |model|
          result = CompositeKeys.new(model).analyze

          assert_nil result, "#{model.name} should not have composite key analysis"
        end

        # And should return composite key info for OrderLineItem
        result = CompositeKeys.new(OrderLineItem).analyze

        assert_not_nil result, 'OrderLineItem should have composite key analysis'
      end

      def test_analyze_composite_key_formatting
        # Test that composite key info is properly formatted
        analyzer = CompositeKeys.new(OrderLineItem)
        result = analyzer.analyze

        # Should have proper section header
        assert_match(/^== Composite Primary Key$/, result)

        # Should have proper key listing
        assert_match(/^Primary Keys: order_id, line_number$/, result)
      end

      def test_analyze_handles_nil_primary_key
        # Test with model that has nil primary key
        User.stub(:primary_key, nil) do
          analyzer = CompositeKeys.new(User)
          result = analyzer.analyze

          assert_nil result, 'Model with nil primary_key should return nil'
        end
      end

      def test_analyze_works_across_different_databases
        # Test that composite key analysis works across different database adapters

        # PostgreSQL model with composite key
        pg_result = CompositeKeys.new(OrderLineItem).analyze

        assert_not_nil pg_result, 'OrderLineItem (PostgreSQL) should have composite key analysis'
        assert_match(/Primary Keys: order_id, line_number/, pg_result)

        # Other database models without composite keys
        mysql_result = CompositeKeys.new(Vehicle).analyze  # MySQL
        sqlite_result = CompositeKeys.new(Family).analyze  # SQLite

        assert_nil mysql_result, 'Vehicle (MySQL) should not have composite key analysis'
        assert_nil sqlite_result, 'Family (SQLite) should not have composite key analysis'
      end

      def test_analyze_real_world_composite_key_behavior
        # Test with actual Rails composite key behavior

        # Verify OrderLineItem has proper composite key setup
        assert_kind_of Array, OrderLineItem.primary_key, 'OrderLineItem primary_key should be an array'
        assert_equal 2, OrderLineItem.primary_key.length, 'OrderLineItem should have 2 primary key columns'

        # Test the analyzer detects this correctly
        analyzer = CompositeKeys.new(OrderLineItem)
        result = analyzer.analyze

        assert_includes result, '== Composite Primary Key'
        assert_includes result, 'Primary Keys: order_id, line_number'
      end

      def test_analyze_composite_key_with_database_connection
        # Test that the analyzer works with the actual database table

        # OrderLineItem should exist in the database
        assert_predicate OrderLineItem, :table_exists?, 'OrderLineItem table should exist'

        # Should have the expected columns
        expected_columns = %w[order_id line_number quantity unit_price total_price product_name notes created_at
                              updated_at]
        actual_columns = OrderLineItem.column_names

        expected_columns.each do |col|
          assert_includes actual_columns, col, "OrderLineItem should have #{col} column"
        end

        # Analyzer should work with real database connection
        analyzer = CompositeKeys.new(OrderLineItem)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/Composite Primary Key/, result)
      end
    end
  end
end
