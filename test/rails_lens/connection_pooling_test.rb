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
        test_models = @model_classes

        # Monkey patch ModelDetector to return our test models
        original_detect = ModelDetector.method(:detect_models)
        ModelDetector.define_singleton_method(:detect_models) do |_options|
          test_models
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
        pool = ApplicationRecord.connection_pool

        # Run annotation multiple times
        3.times do
          AnnotationManager.annotate_all
        end

        # All connections should be idle after annotation completes
        # (the test thread may hold 1 connection, but no extras should be busy)
        busy_after = pool.stat[:busy]

        assert_operator busy_after, :<=, 1, "Expected at most 1 busy connection (test thread), got #{busy_after}"
      end

      def test_multi_database_uses_separate_connections
        # This test would verify that models from different databases
        # use different connections but share connections within each database
      end
    end
  end
end
