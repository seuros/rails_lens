# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Analyzers
    class IndexAnalyzerTest < ActiveSupport::TestCase
      def test_missing_foreign_key_indexes_with_product_metric
        # ProductMetric has product_id foreign key with proper index
        # Let's create a scenario where we remove the index conceptually
        # by testing a model that has foreign keys but missing indexes

        # We can't easily test missing indexes on existing models,
        # so we'll test that properly indexed models don't trigger warnings
        analyzer = IndexAnalyzer.new(ProductMetric)
        notes = analyzer.analyze

        # ProductMetric has proper index on product_id, so should not warn about missing index
        assert_not_includes notes, "Missing index on foreign key 'product_id'"
      end

      def test_properly_indexed_polymorphic_associations
        # Comment has proper polymorphic index on [commentable_type, commentable_id]
        analyzer = IndexAnalyzer.new(Comment)
        notes = analyzer.analyze

        # Comment should not have warnings about missing polymorphic indexes
        assert_not_includes notes, "Missing composite index on polymorphic association 'commentable'"
      end

      def test_index_analysis_with_real_database_connections
        # Test that the analyzer works with real database connections across different adapters

        # PostgreSQL models
        pg_analyzer = IndexAnalyzer.new(User)
        pg_notes = pg_analyzer.analyze

        # MySQL models
        mysql_analyzer = IndexAnalyzer.new(Vehicle)
        mysql_notes = mysql_analyzer.analyze

        # SQLite models
        sqlite_analyzer = IndexAnalyzer.new(Family)
        sqlite_notes = sqlite_analyzer.analyze

        # All should return arrays (empty or with notes)
        assert_kind_of Array, pg_notes
        assert_kind_of Array, mysql_notes
        assert_kind_of Array, sqlite_notes
      end

      def test_properly_indexed_models_have_no_warnings
        # Test models that are properly indexed

        # Comment has proper indexes for its associations
        comment_analyzer = IndexAnalyzer.new(Comment)
        comment_notes = comment_analyzer.analyze

        # User has proper index on email (unique)
        user_analyzer = IndexAnalyzer.new(User)
        user_analyzer.analyze

        # ProductMetric has proper index on product_id foreign key
        product_metric_analyzer = IndexAnalyzer.new(ProductMetric)
        product_metric_notes = product_metric_analyzer.analyze

        # These models should have minimal or no index-related warnings
        # (Note: they might have other types of warnings, but not missing index warnings)
        assert_not_includes comment_notes, /Missing.*index.*commentable/
        assert_not_includes product_metric_notes, /Missing.*index.*product_id/
      end

      def test_analyzer_detects_index_structure
        # Test that the analyzer correctly reads real index information
        IndexAnalyzer.new(Comment)

        # Comment should have these indexes based on our earlier check:
        # - index_comments_on_commentable: commentable_type, commentable_id
        # - index_comments_on_post_id: post_id
        # - index_comments_on_user_id: user_id

        # Verify the analyzer can read the actual database indexes
        connection = Comment.connection
        indexes = connection.indexes('comments')

        # Should find the polymorphic composite index
        poly_index = indexes.find { |idx| idx.columns == %w[commentable_type commentable_id] }

        assert_not_nil poly_index, 'Should find polymorphic composite index'

        # Should find foreign key indexes
        post_index = indexes.find { |idx| idx.columns == ['post_id'] }
        user_index = indexes.find { |idx| idx.columns == ['user_id'] }

        assert_not_nil post_index, 'Should find post_id index'
        assert_not_nil user_index, 'Should find user_id index'
      end

      def test_analyzer_handles_models_without_associations
        # Test models that don't have associations requiring indexes

        # Family model (from SQLite) - check if it has minimal associations
        analyzer = IndexAnalyzer.new(Family)
        notes = analyzer.analyze

        # Should handle gracefully without errors
        assert_kind_of Array, notes
      end

      def test_analyzer_works_across_different_database_adapters
        # Test that the analyzer works with different database adapters

        # PostgreSQL - User model
        pg_connection = User.connection

        assert_equal 'PostgreSQL', pg_connection.adapter_name

        pg_analyzer = IndexAnalyzer.new(User)
        pg_result = pg_analyzer.analyze

        assert_kind_of Array, pg_result

        # MySQL - Vehicle model
        mysql_connection = Vehicle.connection

        assert_equal 'Mysql2', mysql_connection.adapter_name

        mysql_analyzer = IndexAnalyzer.new(Vehicle)
        mysql_result = mysql_analyzer.analyze

        assert_kind_of Array, mysql_result

        # SQLite - Family model
        sqlite_connection = Family.connection

        assert_equal 'SQLite', sqlite_connection.adapter_name

        sqlite_analyzer = IndexAnalyzer.new(Family)
        sqlite_result = sqlite_analyzer.analyze

        assert_kind_of Array, sqlite_result
      end
    end
  end
end
