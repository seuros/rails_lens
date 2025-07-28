# frozen_string_literal: true

require 'test_helper'
require 'rails_lens/erd/visualizer'

module RailsLens
  module ERD
    class VisualizerTest < ActiveSupport::TestCase
      def setup
        @visualizer = RailsLens::ERD::Visualizer.new
      end

      def test_visualizer_initializes
        assert_instance_of RailsLens::ERD::Visualizer, @visualizer
        assert_equal 'doc/erd', @visualizer.config[:output_dir]
      end

      def test_visualizer_with_custom_options
        visualizer = RailsLens::ERD::Visualizer.new(
          options: { output_dir: 'tmp/erd', orientation: 'LR' }
        )

        assert_equal 'tmp/erd', visualizer.config[:output_dir]
        assert_equal 'LR', visualizer.config[:orientation]
      end

      def test_group_by_database_option
        visualizer = RailsLens::ERD::Visualizer.new(
          options: { group_by_database: true }
        )

        # Use real models from dummy app with different database connections
        # User uses primary (PostgreSQL), Vehicle uses vehicles (MySQL), Family uses prehistoric (SQLite)
        models = [User, Vehicle, Family]

        # Test grouping by database
        grouped = visualizer.send(:group_models_by_database, models)

        # Verify that models are grouped by their database connections
        assert_equal 3, grouped.keys.length
        assert_includes grouped.keys, 'primary'    # User
        assert_includes grouped.keys, 'vehicles'   # Vehicle
        assert_includes grouped.keys, 'prehistoric' # Family

        # Verify each database group contains the correct models
        assert_equal [User], grouped['primary']
        assert_equal [Vehicle], grouped['vehicles']
        assert_equal [Family], grouped['prehistoric']
      end
    end
  end
end
