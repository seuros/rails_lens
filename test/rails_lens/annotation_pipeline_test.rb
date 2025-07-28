# frozen_string_literal: true

require 'test_helper'

module RailsLens
  class AnnotationPipelineTest < ActiveSupport::TestCase
    def setup
      @pipeline = AnnotationPipeline.new
      @pipeline.clear # Start with empty pipeline for testing

      @model_class = User
    end

    def test_process_with_schema_provider
      # Create a real test schema provider
      test_provider = Class.new(Providers::Base) do
        def type
          :schema
        end

        def applicable?(model_class)
          model_class == User
        end

        def process(model_class)
          "table = \"#{model_class.table_name}\"\ncolumns = []"
        end
      end.new

      @pipeline.register(test_provider)
      results = @pipeline.process(@model_class)

      assert_equal "table = \"users\"\ncolumns = []", results[:schema]
      assert_empty results[:sections]
      assert_empty results[:notes]
    end

    def test_process_with_section_provider
      # Create a real test section provider
      test_provider = Class.new(Providers::Base) do
        def type
          :section
        end

        def applicable?(model_class)
          model_class == User
        end

        def process(_model_class)
          { title: '== Enums', content: 'status: active, inactive' }
        end
      end.new

      @pipeline.register(test_provider)
      results = @pipeline.process(@model_class)

      assert_nil results[:schema]
      assert_equal 1, results[:sections].length
      assert_equal '== Enums', results[:sections].first[:title]
      assert_equal 'status: active, inactive', results[:sections].first[:content]
    end

    def test_process_with_notes_provider
      # Create a real test notes provider
      test_provider = Class.new(Providers::Base) do
        def type
          :notes
        end

        def applicable?(model_class)
          model_class == User
        end

        def process(_model_class)
          ['Missing index on user_id', 'Consider adding NOT NULL']
        end
      end.new

      @pipeline.register(test_provider)
      results = @pipeline.process(@model_class)

      assert_nil results[:schema]
      assert_empty results[:sections]
      assert_equal 2, results[:notes].length
      assert_includes results[:notes], 'Missing index on user_id'
      assert_includes results[:notes], 'Consider adding NOT NULL'
    end

    def test_process_skips_non_applicable_providers
      # Create a real test provider that is not applicable to User model
      test_provider = Class.new(Providers::Base) do
        def type
          :notes
        end

        def applicable?(model_class)
          model_class != User # Not applicable to User
        end

        def process(_model_class)
          ['Should not be processed']
        end
      end.new

      @pipeline.register(test_provider)
      results = @pipeline.process(@model_class)

      assert_nil results[:schema]
      assert_empty results[:sections]
      assert_empty results[:notes]
    end

    def test_process_handles_provider_errors_gracefully
      # Clear existing providers and only use failing one
      @pipeline.clear

      failing_provider = Class.new(Providers::Base) do
        def type
          :notes
        end

        def process(_model_class)
          raise StandardError, 'Provider failed'
        end
      end.new

      @pipeline.stub(:warn, nil) do
        @pipeline.register(failing_provider)
        results = @pipeline.process(@model_class)

        assert_nil results[:schema]
        assert_empty results[:sections]
        assert_empty results[:notes]
      end
    end

    def test_unregister_removes_provider
      provider1 = Providers::SchemaProvider.new
      provider2 = Providers::IndexNotesProvider.new

      @pipeline.register(provider1)
      @pipeline.register(provider2)

      assert_equal 2, @pipeline.providers.length

      @pipeline.unregister(Providers::SchemaProvider)

      assert_equal 1, @pipeline.providers.length
      assert_instance_of Providers::IndexNotesProvider, @pipeline.providers.first
    end
  end
end
