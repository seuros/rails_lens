# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Analyzers
    class DelegatedTypesTest < ActiveSupport::TestCase
      def test_analyze_with_real_delegated_type_model
        # Entry model has real delegated_type :entryable, types: %w[Message Announcement Alert]
        analyzer = DelegatedTypes.new(Entry)
        result = analyzer.analyze

        assert_not_nil result, 'Entry should be detected as having delegated types'
        assert_match(/\[delegated_type\]/, result)
        assert_match(/type_column = "entryable_type"/, result)
        assert_match(/id_column = "entryable_id"/, result)
        assert_match(/types = \[/, result)

        # Should list the known types in TOML array format
        assert_match(/"Alert"/, result)
        assert_match(/"Announcement"/, result)
        assert_match(/"Message"/, result)
      end

      def test_analyze_with_models_without_delegated_types
        # Test models that don't have delegated types
        [User, Post, Vehicle, Family].each do |model|
          analyzer = DelegatedTypes.new(model)
          result = analyzer.analyze

          assert_nil result, "#{model.name} should not have delegated type info"
        end
      end

      def test_analyze_delegated_type_formatting
        # Test that delegated type info is properly formatted in TOML
        analyzer = DelegatedTypes.new(Entry)
        result = analyzer.analyze

        assert_not_nil result, 'Entry should have delegated type analysis'

        # Should have proper TOML section header
        assert_match(/^\[delegated_type\]$/, result)

        # Should have proper TOML key=value formatting
        lines = result.split("\n")
        type_column_line = lines.find { |line| line.include?('type_column =') }
        id_column_line = lines.find { |line| line.include?('id_column =') }

        assert_not_nil type_column_line, 'Should have type column line'
        assert_not_nil id_column_line, 'Should have ID column line'
      end

      def test_analyze_respects_actual_delegated_type_methods
        # Verify that Entry model has the actual Rails delegated_type methods

        # Entry should have entryable_types method (provided by delegated_type)
        assert_respond_to Entry, :entryable_types
        types = Entry.entryable_types

        assert_not_nil types, 'Entry should have entryable_types'

        # Should have the expected types from the delegated_type declaration
        expected_types = %w[Message Announcement Alert]

        assert_equal expected_types, types

        # Should have the reflection for the polymorphic association
        reflection = Entry.reflections['entryable']

        assert_not_nil reflection, 'Entry should have entryable reflection'
        assert_predicate reflection, :polymorphic?, 'entryable should be polymorphic'

        # Analyzer should work with this real delegated type setup
        analyzer = DelegatedTypes.new(Entry)
        result = analyzer.analyze

        # The analyzer should detect the delegated type based on column structure
        assert_not_nil result, 'Entry should be detected as having delegated types'
        assert_includes result, 'entryable_type'
        assert_includes result, 'entryable_id'
      end

      def test_analyze_with_polymorphic_but_not_delegated_type
        # Comment has polymorphic associations but not delegated types
        analyzer = DelegatedTypes.new(Comment)
        result = analyzer.analyze

        # Should not detect delegated types for regular polymorphic associations
        assert_nil result, 'Comment should not have delegated type info (has polymorphic but not delegated_type)'
      end

      def test_analyze_delegated_type_across_databases
        # Test that delegated type analysis works with PostgreSQL
        # Entry uses the primary (PostgreSQL) database

        analyzer = DelegatedTypes.new(Entry)
        result = analyzer.analyze

        assert_not_nil result, 'Entry (PostgreSQL) should have delegated type analysis'
        assert_match(/\[delegated_type\]/, result)

        # Models from other databases should not have delegated types
        mysql_result = DelegatedTypes.new(Vehicle).analyze  # MySQL
        sqlite_result = DelegatedTypes.new(Family).analyze  # SQLite

        assert_nil mysql_result, 'Vehicle (MySQL) should not have delegated types'
        assert_nil sqlite_result, 'Family (SQLite) should not have delegated types'
      end

      def test_analyze_delegated_type_with_database_data
        # Test that the analyzer can detect types from actual database data
        # This tests the real-world scenario where types are discovered from data

        # Entry should exist in the database
        assert_predicate Entry, :table_exists?, 'Entry table should exist'

        # Should have the expected columns
        expected_columns = %w[id title published entryable_type entryable_id created_at updated_at]
        actual_columns = Entry.column_names

        expected_columns.each do |col|
          assert_includes actual_columns, col, "Entry should have #{col} column"
        end

        # Analyzer should work with real database connection
        analyzer = DelegatedTypes.new(Entry)
        result = analyzer.analyze

        assert_not_nil result, 'Entry should have delegated type analysis'
        assert_match(/delegated_type/, result)
      end

      def test_analyze_delegated_type_with_real_rails_methods
        # Test that we can call the actual Rails delegated_type methods

        # Entry should respond to delegated_type class method
        assert_respond_to Entry, :entryable_types

        types = Entry.entryable_types

        assert_equal %w[Message Announcement Alert], types

        # Entry should have the polymorphic reflection
        reflection = Entry.reflections['entryable']

        assert_not_nil reflection
        assert_equal 'entryable_type', reflection.foreign_type
        assert_equal 'entryable_id', reflection.foreign_key

        # Entry should have the required columns
        assert_includes Entry.column_names, 'entryable_type'
        assert_includes Entry.column_names, 'entryable_id'

        # Test that the analyzer can work with this setup
        analyzer = DelegatedTypes.new(Entry)
        result = analyzer.analyze

        # The analyzer should properly detect the delegated type
        assert_not_nil result, 'Entry delegated type should be detected by analyzer'
        assert_includes result, 'entryable_type'
        assert_includes result, 'entryable_id'
      end

      def test_analyze_handles_models_without_delegated_type_gracefully
        # Test that models without delegated_type don't cause errors

        models_without_delegated_types = [User, Post, Product, Vehicle, Family, Spaceship]

        models_without_delegated_types.each do |model|
          # Should not respond to delegated_type_reflection or it should be nil
          reflection = model.respond_to?(:delegated_type_reflection) ? model.delegated_type_reflection : nil

          next unless reflection.nil?

          analyzer = DelegatedTypes.new(model)
          result = analyzer.analyze

          assert_nil result, "#{model.name} without delegated types should return nil"
        end
      end
    end
  end
end
