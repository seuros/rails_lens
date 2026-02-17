# frozen_string_literal: true

require 'test_helper'

module RailsLens
  class ModelDetectorTest < ActiveSupport::TestCase
    def setup
      # Clear view cache for clean slate
      ModelDetector.instance_variable_set(:@view_cache, nil)
    end

    def teardown
      # Reset view cache
      ModelDetector.instance_variable_set(:@view_cache, nil)
    end

    # Test 1: Verify system views are NOT detected as user views
    test 'does not detect PostgreSQL system view when user table has same name' do
      # The 'triggers' table exists in the dummy app, but should NOT be detected as a view
      # because it's not in information_schema.triggers (which is a system view)
      refute ModelDetector.view_exists?(Trigger),
        "Should not detect information_schema.triggers as user view for Trigger model"
    end

    # Test 2: Verify legitimate user views still work (PostgreSQL regular view)
    test 'detects legitimate PostgreSQL user views after fix' do
      assert ModelDetector.view_exists?(CrewMissionStats),
        "Should still detect CrewMissionStats as a view"
    end

    # Test 3: Verify PostgreSQL materialized views still work
    test 'detects PostgreSQL materialized views after fix' do
      assert ModelDetector.view_exists?(SpatialAnalysis),
        "Should still detect SpatialAnalysis materialized view"
    end

    # Test 4: Verify MySQL baseline (unchanged)
    test 'MySQL view detection still works correctly' do
      assert ModelDetector.view_exists?(VehiclePerformanceMetrics),
        "MySQL view detection should be unaffected"
    end

    # Test 5: Verify SQLite baseline (unchanged)
    test 'SQLite view detection still works correctly' do
      assert ModelDetector.view_exists?(FossilDiscoveryTimeline),
        "SQLite view detection should be unaffected"
    end

    # Test 6: View caching works correctly
    test 'caches view existence checks' do
      # First call populates cache
      result1 = ModelDetector.view_exists?(CrewMissionStats)
      cache1 = ModelDetector.instance_variable_get(:@view_cache)

      # Second call should use cache
      result2 = ModelDetector.view_exists?(CrewMissionStats)
      cache2 = ModelDetector.instance_variable_get(:@view_cache)

      assert_equal result1, result2
      assert_equal cache1, cache2
      assert cache2.present?, "Cache should be populated"
    end

    # Test 7: Regular table detection
    test 'correctly identifies regular tables as non-views' do
      refute ModelDetector.view_exists?(User),
        "User should not be detected as a view"

      refute ModelDetector.view_exists?(Post),
        "Post should not be detected as a view"

      refute ModelDetector.view_exists?(Trigger),
        "Trigger should not be detected as a view (has system view collision)"
    end

    # Test 8: View-backed models classification
    test 'view_backed_models returns only models backed by views' do
      view_backed = ModelDetector.view_backed_models

      assert_includes view_backed, CrewMissionStats,
        "Should include CrewMissionStats (regular view)"

      assert_includes view_backed, SpatialAnalysis,
        "Should include SpatialAnalysis (materialized view)"

      refute_includes view_backed, Trigger,
        "Should not include Trigger (regular table with system view name collision)"

      refute_includes view_backed, User,
        "Should not include User (regular table)"
    end

    # Test 9: Table-backed models classification
    test 'table_backed_models returns only models backed by tables' do
      table_backed = ModelDetector.table_backed_models

      assert_includes table_backed, User,
        "Should include User (regular table)"

      assert_includes table_backed, Trigger,
        "Should include Trigger (regular table, not a view)"

      refute_includes table_backed, CrewMissionStats,
        "Should not include CrewMissionStats (view)"

      refute_includes table_backed, SpatialAnalysis,
        "Should not include SpatialAnalysis (materialized view)"
    end

    # Test 10: Schema-qualified table names (if applicable)
    test 'handles schema-qualified table names correctly' do
      # The audit.audit_logs table is schema-qualified
      # Only test if the model exists and has a schema-qualified name
      if defined?(AuditLog) && AuditLog.table_name.include?('.')
        refute ModelDetector.view_exists?(AuditLog),
          "Should not detect audit.audit_logs as a view"
      end
    end
  end
end
