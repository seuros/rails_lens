# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Analyzers
    class BestPracticesAnalyzerTest < ActiveSupport::TestCase
      # Mock model class for testing
      class MockModel
        attr_reader :table_name, :columns, :connection

        def initialize(table_name, columns = [], connection = nil)
          @table_name = table_name
          @columns = columns
          @connection = connection || MockConnection.new
        end

        def self.base_class
          self
        end

        def column_names
          @columns.map(&:name)
        end
      end

      # Mock connection for testing
      class MockConnection
        def indexes(_table_name)
          []
        end
      end

      # Mock column for testing
      MockColumn = Struct.new(:name, :type, :null, :default, keyword_init: true)

      def setup
        @timestamp_columns = [
          MockColumn.new(name: 'id', type: :integer, null: false),
          MockColumn.new(name: 'created_at', type: :datetime, null: false),
          MockColumn.new(name: 'updated_at', type: :datetime, null: false)
        ]
      end

      def test_schema_qualified_table_name_plural
        # Test that schema-qualified plural table names pass validation
        model = MockModel.new('ai.skills', @timestamp_columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        # Should not complain about plural, snake_case for "skills"
        assert_not_includes notes, "Table name 'ai.skills' doesn't follow Rails conventions (should be plural, snake_case)"
      end

      def test_schema_qualified_table_name_singular
        # Test that schema-qualified singular table names are flagged
        model = MockModel.new('cms.post', @timestamp_columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        # Should complain about singular "post" (should be "posts")
        assert_includes notes, "Table name 'cms.post' doesn't follow Rails conventions (should be plural, snake_case)"
      end

      def test_regular_table_name_plural
        # Test that regular plural table names pass validation
        model = MockModel.new('products', @timestamp_columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_not_includes notes, "Table name 'products' doesn't follow Rails conventions (should be plural, snake_case)"
      end

      def test_regular_table_name_singular
        # Test that regular singular table names are flagged
        model = MockModel.new('product', @timestamp_columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, "Table name 'product' doesn't follow Rails conventions (should be plural, snake_case)"
      end

      def test_table_name_with_camelcase
        # Test that CamelCase table names are flagged
        model = MockModel.new('UserProfiles', @timestamp_columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, "Table name 'UserProfiles' doesn't follow Rails conventions (should be plural, snake_case)"
      end

      def test_schema_qualified_table_name_with_camelcase
        # Test that schema-qualified CamelCase table names are flagged
        model = MockModel.new('auth.UserTokens', @timestamp_columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, "Table name 'auth.UserTokens' doesn't follow Rails conventions (should be plural, snake_case)"
      end

      def test_timestamp_columns_present
        # Test that models with both timestamps don't get flagged
        model = MockModel.new('users', @timestamp_columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_not_includes notes, 'Missing timestamp columns (created_at, updated_at)'
      end

      def test_timestamp_columns_missing
        # Test that models without timestamps get flagged
        columns = [
          MockColumn.new(name: 'id', type: :integer, null: false),
          MockColumn.new(name: 'name', type: :string, null: true)
        ]
        model = MockModel.new('users', columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, 'Missing timestamp columns (created_at, updated_at)'
      end

      def test_partial_timestamp_columns
        # Test that models with partial timestamps get flagged
        columns = [
          MockColumn.new(name: 'id', type: :integer, null: false),
          MockColumn.new(name: 'created_at', type: :datetime, null: false)
        ]
        model = MockModel.new('users', columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, 'Has created_at but missing updated_at'
      end

      def test_column_with_is_prefix
        # Test that columns with is_ prefix get flagged
        columns = @timestamp_columns + [
          MockColumn.new(name: 'is_active', type: :boolean, null: true)
        ]
        model = MockModel.new('users', columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, "Column 'is_active' uses non-conventional prefix - consider removing 'is_' or 'has_'"
      end

      def test_column_with_has_prefix
        # Test that columns with has_ prefix get flagged
        columns = @timestamp_columns + [
          MockColumn.new(name: 'has_profile', type: :boolean, null: true)
        ]
        model = MockModel.new('users', columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, "Column 'has_profile' uses non-conventional prefix - consider removing 'is_' or 'has_'"
      end

      def test_column_with_camelcase
        # Test that CamelCase column names get flagged
        columns = @timestamp_columns + [
          MockColumn.new(name: 'userId', type: :integer, null: true)
        ]
        model = MockModel.new('users', columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, "Column 'userId' should use snake_case (e.g., 'user_id')"
      end

      def test_soft_delete_column_without_index
        # Test soft delete columns are checked for indexes
        columns = @timestamp_columns + [
          MockColumn.new(name: 'deleted_at', type: :datetime, null: true)
        ]
        model = MockModel.new('users', columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, "Soft delete column 'deleted_at' should be indexed"
      end

      def test_sti_type_column
        # Test STI type column handling
        columns = @timestamp_columns + [
          MockColumn.new(name: 'type', type: :string, null: true)
        ]
        model = MockModel.new('users', columns)
        analyzer = BestPracticesAnalyzer.new(model)

        notes = analyzer.analyze

        assert_includes notes, "STI type column 'type' should be indexed"
        assert_includes notes, "STI type column 'type' should have NOT NULL constraint"
      end

      # Integration test with real database models if available
      def test_with_actual_models_if_available
        skip 'Requires database connection' unless defined?(User) && User.connected?

        # Test with a real model if available
        analyzer = BestPracticesAnalyzer.new(User)
        notes = analyzer.analyze

        # Should return an array of notes (may be empty)
        assert_kind_of Array, notes
      end

      def test_schema_qualified_with_special_pluralization
        # Test special pluralization cases with schema-qualified names
        # PostgreSQL format is schema.table (e.g., public.users, ai.skills)
        test_cases = {
          'ai.skill' => true, # singular, should be flagged (should be skills)
          'ai.skills' => false, # plural, correct
          'cms.category' => true, # singular, should be flagged (should be categories)
          'cms.categories' => false, # plural, correct
          'auth.person' => true, # singular, should be flagged (should be people)
          'auth.people' => false, # plural, correct (irregular)
          'analytics.datum' => true, # singular, should be flagged (should be data)
          'analytics.data' => false # plural, correct (irregular)
        }

        test_cases.each do |table_name, should_flag|
          model = MockModel.new(table_name, @timestamp_columns)
          analyzer = BestPracticesAnalyzer.new(model)
          notes = analyzer.analyze

          if should_flag
            assert_includes notes, "Table name '#{table_name}' doesn't follow Rails conventions (should be plural, snake_case)",
                            "Expected #{table_name} to be flagged as non-conventional"
          else
            assert_not_includes notes, "Table name '#{table_name}' doesn't follow Rails conventions (should be plural, snake_case)",
                                "Expected #{table_name} to pass validation"
          end
        end
      end
    end
  end
end
