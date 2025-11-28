# frozen_string_literal: true

require 'test_helper'

module RailsLens
  class ViewMetadataTest < ActiveSupport::TestCase
    def setup
      # Ensure we're working with a clean state
      @original_view_cache = ModelDetector.instance_variable_get(:@view_cache)
      ModelDetector.instance_variable_set(:@view_cache, nil)
    end

    def teardown
      # Restore original cache state
      ModelDetector.instance_variable_set(:@view_cache, @original_view_cache)
    end

    test 'detects PostgreSQL regular views' do
      metadata = ViewMetadata.new(CrewMissionStats)

      assert_predicate metadata, :view_exists?
      assert_equal 'regular', metadata.view_type
      assert_predicate metadata, :regular_view?
      assert_not metadata.materialized_view?
    end

    test 'detects PostgreSQL materialized views' do
      metadata = ViewMetadata.new(SpatialAnalysis)

      assert_predicate metadata, :view_exists?
      assert_equal 'materialized', metadata.view_type
      assert_not metadata.regular_view?
      assert_predicate metadata, :materialized_view?
      assert_equal 'manual', metadata.refresh_strategy
    end

    test 'detects MySQL views' do
      metadata = ViewMetadata.new(VehiclePerformanceMetrics)

      assert_predicate metadata, :view_exists?
      assert_equal 'regular', metadata.view_type
      assert_predicate metadata, :regular_view?
      assert_not metadata.materialized_view?
    end

    test 'detects SQLite views' do
      metadata = ViewMetadata.new(FossilDiscoveryTimeline)

      assert_predicate metadata, :view_exists?
      assert_equal 'regular', metadata.view_type
      assert_predicate metadata, :regular_view?
      assert_not metadata.materialized_view?
      assert_not metadata.updatable? # SQLite views are always read-only
    end

    test 'extracts PostgreSQL view dependencies' do
      metadata = ViewMetadata.new(CrewMissionStats)
      dependencies = metadata.dependencies

      assert_kind_of Array, dependencies
      # Dependencies will vary based on actual view definition
    end

    test 'extracts MySQL view dependencies' do
      metadata = ViewMetadata.new(VehiclePerformanceMetrics)
      dependencies = metadata.dependencies

      assert_kind_of Array, dependencies
    end

    test 'extracts SQLite view dependencies' do
      metadata = ViewMetadata.new(FossilDiscoveryTimeline)
      dependencies = metadata.dependencies

      assert_kind_of Array, dependencies
    end

    test 'handles connection errors gracefully' do
      # Test with a model that has connection issues
      # The ViewMetadata.new requires a working connection to initialize,
      # so we test with a nonexistent table instead
      metadata = ViewMetadata.new(MockNonexistentViewModel)

      assert_not metadata.view_exists?
      assert_nil metadata.view_type
      assert_empty metadata.dependencies
      assert_nil metadata.view_definition
    end

    test 'returns view metadata hash' do
      metadata = ViewMetadata.new(CrewMissionStats)
      hash = metadata.to_h

      assert_kind_of Hash, hash
      assert_includes hash.keys, :view_type
      assert_includes hash.keys, :updatable
      assert_includes hash.keys, :dependencies
    end

    class MockNonexistentViewModel < ApplicationRecord
      self.table_name = 'nonexistent_view_that_does_not_exist'
    end
  end
end
