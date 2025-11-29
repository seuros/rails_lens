# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Analyzers
    class EnumsTest < ActiveSupport::TestCase
      def test_analyze_with_vehicle_string_enums
        # Vehicle model has real string-based enums: vehicle_type and status
        analyzer = Enums.new(Vehicle)
        result = analyzer.analyze

        assert_match(/\[enums\]/, result)

        # Should include vehicle_type enum in TOML format
        assert_match(/vehicle_type = \{/, result)
        assert_match(/car = "car"/, result)
        assert_match(/truck = "truck"/, result)
        assert_match(/motorcycle = "motorcycle"/, result)
        assert_match(/electric = "electric"/, result)

        # Should include status enum
        assert_match(/status = \{/, result)
        assert_match(/active = "active"/, result)
        assert_match(/maintenance = "maintenance"/, result)
        assert_match(/impounded = "impounded"/, result)
        assert_match(/scrapped = "scrapped"/, result)
      end

      def test_analyze_with_family_string_enums
        # Family model has string-based enums: classification and taxonomic_rank
        analyzer = Enums.new(Family)
        result = analyzer.analyze

        assert_match(/\[enums\]/, result)

        # Should include classification enum in TOML format
        assert_match(/classification = \{/, result)
        assert_match(/theropod = "theropod"/, result)
        assert_match(/sauropod = "sauropod"/, result)
        assert_match(/ceratopsian = "ceratopsian"/, result)

        # Should include taxonomic_rank enum
        assert_match(/taxonomic_rank = \{/, result)
        assert_match(/kingdom = "kingdom"/, result)
        assert_match(/phylum = "phylum"/, result)
        assert_match(/family = "family"/, result)
        assert_match(/species = "species"/, result)
      end

      def test_analyze_with_user_model_without_enums
        # User model doesn't have enums, should return nil
        analyzer = Enums.new(User)
        result = analyzer.analyze

        assert_nil result, 'User model should not have enums, expected nil'
      end

      def test_analyze_with_post_model_without_enums
        # Post model doesn't have enums, should return nil
        analyzer = Enums.new(Post)
        result = analyzer.analyze

        assert_nil result, 'Post model should not have enums, expected nil'
      end

      def test_analyze_handles_model_with_empty_enums
        # Test with a model that has defined_enums method but empty hash
        analyzer = Enums.new(Product)
        result = analyzer.analyze

        # Should return nil for models without enums
        assert_nil result, 'Product model should not have enums, expected nil'
      end

      def test_analyze_enum_formatting
        # Test that enum formatting includes proper TOML section header and structure
        analyzer = Enums.new(Vehicle)
        result = analyzer.analyze

        # Should have proper TOML section formatting
        assert_match(/^\[enums\]$/, result)

        # Should have proper TOML key-value format
        assert_match(/^vehicle_type = \{/, result)
        assert_match(/^status = \{/, result)
      end

      def test_analyze_enum_values_are_properly_quoted
        # Ensure string values are properly quoted in output
        analyzer = Enums.new(Vehicle)
        result = analyzer.analyze

        # String enum values should be in quotes (TOML format)
        assert_match(/car = "car"/, result)
        assert_match(/active = "active"/, result)
        assert_match(/maintenance = "maintenance"/, result)
      end

      def test_analyze_multiple_enums_on_same_model
        # Vehicle has multiple enums, ensure both are included
        analyzer = Enums.new(Vehicle)
        result = analyzer.analyze

        # Count enum definitions (TOML format: name = { ... })
        enum_lines = result.split("\n").select { |line| line.match(/^\w+ = \{/) }

        assert_equal 2, enum_lines.length, 'Vehicle should have exactly 2 enums'

        # Verify both enums are present (checking key patterns)
        assert_match(/vehicle_type = \{.*car = "car"/, result)
        assert_match(/status = \{.*active = "active"/, result)
      end

      def test_analyze_with_different_database_models
        # Test enums work across different database adapters

        # MySQL model with enums
        mysql_result = Enums.new(Vehicle).analyze

        assert_not_nil mysql_result, 'Vehicle (MySQL) should have enums'
        assert_match(/\[enums\]/, mysql_result)

        # SQLite model with enums
        sqlite_result = Enums.new(Family).analyze

        assert_not_nil sqlite_result, 'Family (SQLite) should have enums'
        assert_match(/\[enums\]/, sqlite_result)

        # PostgreSQL model without enums
        pg_result = Enums.new(User).analyze

        assert_nil pg_result, 'User (PostgreSQL) should not have enums'
      end

      def test_analyze_respects_model_enum_definitions
        # Verify that the analyzer respects the actual Rails enum definitions
        # rather than making assumptions

        # Vehicle should have exactly the enums defined in the model
        vehicle_enums = Vehicle.defined_enums

        assert_equal 2, vehicle_enums.keys.length
        assert_includes vehicle_enums.keys, 'vehicle_type'
        assert_includes vehicle_enums.keys, 'status'

        # Family should have exactly the enums defined in the model
        family_enums = Family.defined_enums

        assert_equal 2, family_enums.keys.length
        assert_includes family_enums.keys, 'classification'
        assert_includes family_enums.keys, 'taxonomic_rank'

        # Analyzer output should match model definitions
        vehicle_result = Enums.new(Vehicle).analyze
        family_result = Enums.new(Family).analyze

        assert_not_nil vehicle_result
        assert_not_nil family_result
      end
    end
  end
end
