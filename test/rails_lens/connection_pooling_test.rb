# frozen_string_literal: true

require 'test_helper'

module RailsLens
  class ConnectionPoolingTest < Minitest::Test
    def setup
      @pipeline = AnnotationPipeline.new
      @model_class = Class.new(ApplicationRecord) do
        self.table_name = 'users'

        def self.name
          'TestUser'
        end
      end
    end

    def test_uses_single_connection_for_all_providers
      # Create a custom provider that captures the connection object_id
      test_provider = Class.new(Providers::Base) do
        def type
          :notes
        end

        def process(model_class, connection = nil)
          Thread.current[:test_connection_ids] ||= []
          Thread.current[:test_connection_ids] << connection.object_id if connection
          []
        end
      end

      # Clear default providers and add our test provider multiple times
      @pipeline.clear
      5.times { @pipeline.register(test_provider.new) }

      # Process the model
      Thread.current[:test_connection_ids] = []
      @pipeline.process(@model_class)

      # All providers should have received the same connection object
      connection_ids = Thread.current[:test_connection_ids]

      assert_equal 5, connection_ids.length, 'Should have captured 5 connection IDs'
      assert_equal 1, connection_ids.uniq.length, 'All providers should receive the same connection object'
    ensure
      Thread.current[:test_connection_ids] = nil
    end

    def test_connection_released_after_processing
      # This test verifies that connections are properly released back to the pool
      initial_connections = ActiveRecord::Base.connection_pool.connections.size

      # Process multiple models
      3.times do
        @pipeline.process(@model_class)
      end

      # Force a garbage collection to ensure any leaked connections would be visible
      GC.start

      # Connection pool size should not have grown
      final_connections = ActiveRecord::Base.connection_pool.connections.size

      assert_equal initial_connections, final_connections,
                   'Connection pool should not grow after processing'
    end
  end
end
