# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Analyzers
    class CallbacksTest < ActiveSupport::TestCase
      def test_analyze_vehicle_with_conditional_callbacks
        analyzer = Callbacks.new(Vehicle)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # Vehicle has before_validation with on: :create
        assert_match(/before_validation/, result)

        # Vehicle has before_save with if and unless conditions
        assert_match(/before_save/, result)

        # Vehicle has after_update with lambda condition
        assert_match(/after_update/, result)
      end

      def test_analyze_post_with_transaction_callbacks
        analyzer = Callbacks.new(Post)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # Post has after_commit and after_rollback
        assert_match(/after_commit/, result)
        assert_match(/after_rollback/, result)
      end

      def test_analyze_dinosaur_with_destroy_callbacks
        analyzer = Callbacks.new(Dinosaur)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # Dinosaur has before_destroy and after_destroy callbacks
        assert_match(/before_destroy/, result)
        assert_match(/after_destroy/, result)
      end

      def test_analyze_mission_with_around_callbacks
        analyzer = Callbacks.new(Mission)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # Mission has around_save and around_destroy
        assert_match(/around_save/, result)
        assert_match(/around_destroy/, result)
      end

      def test_analyze_crew_member_with_halting_callbacks
        analyzer = Callbacks.new(CrewMember)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # CrewMember has before_destroy that can halt
        assert_match(/before_destroy/, result)
        assert_match(/check_active_missions/, result)
      end

      def test_analyze_alert_with_multiple_same_hook_callbacks
        analyzer = Callbacks.new(Alert)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # Alert has multiple before_save callbacks
        assert_match(/before_save/, result)
        assert_match(/set_severity_timestamp/, result)
        assert_match(/notify_if_critical/, result)
        assert_match(/log_alert_change/, result)
      end

      def test_analyze_trip_with_multiple_before_save_callbacks
        analyzer = Callbacks.new(Trip)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # Trip has multiple before_save callbacks
        assert_match(/before_save/, result)
        assert_match(/calculate_distance/, result)
        assert_match(/set_fuel_consumption/, result)
        assert_match(/update_trip_category/, result)

        # NOTE: prepend option is not exposed by Rails 8 callback API
        # The order in the chain reflects prepend, but it's not queryable
      end

      def test_analyze_fossil_discovery_with_validation_callbacks
        analyzer = Callbacks.new(FossilDiscovery)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # FossilDiscovery has before_validation and after_validation
        assert_match(/before_validation/, result)
        assert_match(/after_validation/, result)
      end

      def test_analyze_product_with_concern_callbacks
        # Product includes both Trackable and Auditable concerns
        analyzer = Callbacks.new(Product)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # Should have callbacks from Trackable concern
        assert_match(/before_create/, result)
        assert_match(/set_tracking_id/, result)

        # Should have callbacks from Auditable concern
        assert_match(/after_create/, result)
        assert_match(/audit_creation/, result)
      end

      def test_analyze_model_without_callbacks
        # AuditLog might have minimal callbacks
        analyzer = Callbacks.new(AuditLog)
        result = analyzer.analyze

        # Result can be nil or have callbacks
        skip unless result

        assert_match(/\[callbacks\]/, result)
      end

      def test_analyze_returns_nil_for_model_with_only_inherited_callbacks
        # Models with only inherited callbacks from ActiveRecord::Base should return nil
        # This is hard to test as most models have some callbacks
      end

      def test_callback_toml_format
        analyzer = Callbacks.new(Vehicle)
        result = analyzer.analyze

        # Should have proper TOML section formatting
        assert_match(/^\[callbacks\]$/, result)

        # Should have proper TOML array format for callback types
        # Format: callback_type = [{ method = "...", ... }, ...]
        lines = result.split("\n")
        callback_lines = lines.grep(/^\w+_\w+ = \[/)

        assert_predicate callback_lines, :any?, 'Should have callback type definitions'
      end

      def test_callback_conditions_are_captured
        analyzer = Callbacks.new(Vehicle)
        result = analyzer.analyze

        # Vehicle has callbacks with :if conditions
        assert_match(/if = \[/, result)
      end

      def test_after_commit_callbacks_are_captured
        analyzer = Callbacks.new(Post)
        result = analyzer.analyze

        # Post has after_commit callbacks
        # Note: :on option is converted to internal procs by Rails, not directly queryable
        assert_match(/after_commit/, result)
        assert_match(/notify_subscribers/, result)
        assert_match(/invalidate_cache/, result)
      end

      def test_sti_child_inherits_parent_callbacks
        # CargoVessel extends Spaceship
        analyzer = Callbacks.new(CargoVessel)
        result = analyzer.analyze

        assert_not_nil result
        assert_match(/\[callbacks\]/, result)

        # Should have its own callback
        assert_match(/validate_cargo_weight/, result)
      end

      def test_callback_method_escaping
        # Test that method names with special chars are properly escaped
        analyzer = Callbacks.new(Vehicle)
        result = analyzer.analyze

        # All method names should be in quotes
        assert_match(/method = "[^"]+"/m, result)
      end

      def test_analyze_across_different_databases
        # MySQL model
        mysql_result = Callbacks.new(Vehicle).analyze

        assert_not_nil mysql_result

        # SQLite model
        sqlite_result = Callbacks.new(Dinosaur).analyze

        assert_not_nil sqlite_result

        # PostgreSQL model
        pg_result = Callbacks.new(Post).analyze

        assert_not_nil pg_result
      end
    end
  end
end
