# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Schema
    class ConnectionPoolingTest < Minitest::Test
      def setup
        @model_classes = [
          Class.new(ApplicationRecord) do
            self.table_name = 'users'
            def self.name
              'TestUser'
            end
          end,
          Class.new(ApplicationRecord) do
            self.table_name = 'posts'
            def self.name
              'TestPost'
            end
          end
        ]
      end

      def test_uses_single_connection_for_models_in_same_database
        connection_ids = []

        # Monkey patch ModelDetector to return our test models
        original_detect = ModelDetector.method(:detect_models)
        ModelDetector.define_singleton_method(:detect_models) do |_options|
          @model_classes
        end

        # Monkey patch the annotation manager to capture connections
        original_process = AnnotationManager.method(:process_model_with_connection)
        AnnotationManager.define_singleton_method(:process_model_with_connection) do |model, connection, results, _options|
          connection_ids << connection.object_id if connection
          results[:annotated] << model.name
        end

        # Run the annotation
        AnnotationManager.annotate_all

        # All models should have been processed with the same connection
        assert_equal 2, connection_ids.length, 'Should have processed 2 models'
        assert_equal 1, connection_ids.uniq.length, 'All models should use the same connection'
      ensure
        # Restore original methods
        ModelDetector.define_singleton_method(:detect_models, original_detect)
        AnnotationManager.define_singleton_method(:process_model_with_connection, original_process)
      end

      def test_connection_released_after_annotation
        # Test that connections are properly released back to the pool
        initial_connections = ApplicationRecord.connection_pool.connections.size

        # Run annotation multiple times
        3.times do
          AnnotationManager.annotate_all
        end

        # Force a garbage collection to ensure any leaked connections would be visible
        GC.start

        # Connection pool size should not have grown
        final_connections = ApplicationRecord.connection_pool.connections.size

        assert_equal initial_connections, final_connections,
                     'Connection pool should not grow after annotation'
      end

      def test_multi_database_uses_separate_connections
        skip 'Multi-database test requires Rails 6+' unless ActiveRecord::Base.respond_to?(:connected_to)

        # This test would verify that models from different databases
        # use different connections but share connections within each database
      end
    end
  end
end
