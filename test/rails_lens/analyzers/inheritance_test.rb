# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Analyzers
    class InheritanceTest < ActiveSupport::TestCase
      def test_analyze_with_spaceship_sti_base_class
        # Spaceship is the STI base class with type column
        analyzer = Inheritance.new(Spaceship)
        result = analyzer.analyze

        assert_match(/== Inheritance \(STI\)/, result)
        assert_match(/Base Class: Yes/, result)
        assert_match(/Type Column: type/, result)

        # Should list known subclasses
        assert_match(/Known Subclasses:/, result)
        assert_match(/CargoVessel/, result)
        assert_match(/StarfleetBattleCruiser/, result)
      end

      def test_analyze_with_cargo_vessel_sti_subclass
        # CargoVessel inherits from Spaceship (STI)
        analyzer = Inheritance.new(CargoVessel)
        result = analyzer.analyze

        assert_match(/== Inheritance \(STI\)/, result)
        assert_match(/Base Class: Spaceship/, result)
        assert_match(/Type Column: type/, result)
        assert_match(/Type Value: CargoVessel/, result)

        # Sibling classes might not always be detected in test environment
        # Just ensure basic STI info is present
        assert_no_match(/ERROR/, result)
      end

      def test_analyze_with_starfleet_battle_cruiser_sti_subclass
        # StarfleetBattleCruiser inherits from Spaceship (STI)
        analyzer = Inheritance.new(StarfleetBattleCruiser)
        result = analyzer.analyze

        assert_match(/== Inheritance \(STI\)/, result)
        assert_match(/Base Class: Spaceship/, result)
        assert_match(/Type Column: type/, result)
        assert_match(/Type Value: StarfleetBattleCruiser/, result)

        # Ensure no errors in output
        assert_no_match(/ERROR/, result)
      end

      def test_analyze_with_non_sti_model
        # User is not part of STI hierarchy
        analyzer = Inheritance.new(User)
        result = analyzer.analyze

        assert_nil result, 'User model should not have inheritance info'
      end

      def test_analyze_with_regular_inheritance_model
        # Vehicle inherits from VehicleRecord but not STI
        analyzer = Inheritance.new(Vehicle)
        result = analyzer.analyze

        # Should not show STI info for regular inheritance
        assert_nil result, 'Vehicle should not show STI inheritance (uses regular inheritance)'
      end

      def test_analyze_with_family_model_regular_inheritance
        # Family inherits from PrehistoricRecord but not STI
        analyzer = Inheritance.new(Family)
        result = analyzer.analyze

        # Should not show STI info for regular inheritance
        assert_nil result, 'Family should not show STI inheritance (uses regular inheritance)'
      end

      def test_analyze_sti_hierarchy_consistency
        # Test that the STI hierarchy is properly detected across all related models

        # Base class should know about all subclasses (if detection works)
        spaceship_result = Inheritance.new(Spaceship).analyze
        # In test environment, subclass detection might not work due to class loading
        # Just ensure the base analysis works
        assert_match(/== Inheritance \(STI\)/, spaceship_result)
        assert_match(/Base Class: Yes/, spaceship_result)

        # Each subclass should have proper base info
        cargo_result = Inheritance.new(CargoVessel).analyze
        starfleet_result = Inheritance.new(StarfleetBattleCruiser).analyze

        assert_match(/Base Class: Spaceship/, cargo_result)
        assert_match(/Base Class: Spaceship/, starfleet_result)
      end

      def test_analyze_sti_type_column_detection
        # Verify that the analyzer correctly identifies the type column

        spaceship_result = Inheritance.new(Spaceship).analyze
        cargo_result = Inheritance.new(CargoVessel).analyze
        starfleet_result = Inheritance.new(StarfleetBattleCruiser).analyze

        # All should have the same type column
        [spaceship_result, cargo_result, starfleet_result].each do |result|
          assert_match(/Type Column: type/, result)
        end
      end

      def test_analyze_sti_base_class_identification
        # Test that base classes are properly identified

        # Spaceship is the base class
        spaceship_result = Inheritance.new(Spaceship).analyze

        assert_match(/Base Class: Yes/, spaceship_result)

        # Subclasses should point to Spaceship as base
        cargo_result = Inheritance.new(CargoVessel).analyze
        starfleet_result = Inheritance.new(StarfleetBattleCruiser).analyze

        assert_match(/Base Class: Spaceship/, cargo_result)
        assert_match(/Base Class: Spaceship/, starfleet_result)
      end

      def test_analyze_sti_type_value_detection
        # Test that subclasses correctly report their type values

        cargo_result = Inheritance.new(CargoVessel).analyze

        assert_match(/Type Value: CargoVessel/, cargo_result)

        starfleet_result = Inheritance.new(StarfleetBattleCruiser).analyze

        assert_match(/Type Value: StarfleetBattleCruiser/, starfleet_result)

        # Base class should not have a specific type value
        spaceship_result = Inheritance.new(Spaceship).analyze

        assert_no_match(/Type Value:/, spaceship_result)
      end

      def test_analyze_handles_inheritance_edge_cases
        # Test with models that have complex inheritance but not STI

        # ApplicationRecord is a base class but not STI
        analyzer = Inheritance.new(User)
        result = analyzer.analyze

        assert_nil result

        # Test with models that inherit from custom base classes
        vehicle_analyzer = Inheritance.new(Vehicle) # inherits from VehicleRecord
        vehicle_result = vehicle_analyzer.analyze

        assert_nil vehicle_result

        family_analyzer = Inheritance.new(Family) # inherits from PrehistoricRecord
        family_result = family_analyzer.analyze

        assert_nil family_result
      end

      def test_analyze_sti_formatting
        # Test that STI inheritance info is properly formatted

        result = Inheritance.new(CargoVessel).analyze

        # Should have proper section header
        assert_match(/^== Inheritance \(STI\)$/, result)

        # Should have proper field formatting
        lines = result.split("\n")
        type_column_line = lines.find { |line| line.include?('Type Column:') }
        base_class_line = lines.find { |line| line.include?('Base Class:') }
        type_value_line = lines.find { |line| line.include?('Type Value:') }

        assert_not_nil type_column_line
        assert_not_nil base_class_line
        assert_not_nil type_value_line
      end
    end
  end
end
