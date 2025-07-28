# frozen_string_literal: true

require 'test_helper'
require 'timeout'

class AnnotationRakeTaskTest < ActiveSupport::TestCase
  setup do
    # Don't change directories - work with full paths
    @dummy_path = File.expand_path('../dummy', __dir__)

    # Create a temporary directory for test models
    @temp_dir = Dir.mktmpdir('rails_lens_test')
    @temp_models_dir = File.join(@temp_dir, 'app', 'models')
    FileUtils.mkdir_p(@temp_models_dir)

    # Copy model files to temp directory
    @test_models = [User, Post, Comment]
    @model_files = {}

    @test_models.each do |model|
      original_path = File.join(@dummy_path, 'app', 'models', "#{model.name.underscore}.rb")
      next unless File.exist?(original_path)

      temp_path = File.join(@temp_models_dir, "#{model.name.underscore}.rb")
      FileUtils.cp(original_path, temp_path)
      @model_files[model] = temp_path
    end

    # No need to setup Rake - the Rails app is already loaded with tasks
  end

  teardown do
    # Clean up temp directory
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  # Instead of testing rake tasks directly, test the underlying functionality
  def test_annotation_manager_can_annotate_and_remove_annotations
    # Test the annotation manager directly instead of through rake
    require 'rails_lens/schema/annotation_manager'

    # Test annotating directly on each model
    @test_models.each do |model|
      file_path = @model_files[model]
      next unless file_path

      # Create an annotation manager for this specific model
      manager = RailsLens::Schema::AnnotationManager.new(model)

      # Annotate the model
      manager.annotate_file(file_path)

      # Verify annotation was added
      content = File.read(file_path)

      assert_includes content, 'rails-lens:schema:begin'
      assert_includes content, 'rails-lens:schema:end'
      assert_includes content, "table = \"#{model.table_name}\""

      # Test removing annotations
      file_path = @model_files[model]
      next unless file_path

      # Create an annotation manager for this specific model
      manager = RailsLens::Schema::AnnotationManager.new(model)

      # Remove annotation
      manager.remove_annotations(file_path)

      # Verify annotation was removed
      content = File.read(file_path)

      assert_not_includes content, 'rails-lens:schema:begin'
      assert_not_includes content, 'rails-lens:schema:end'
    end
  end

  def test_annotation_respects_position_configuration
    require 'rails_lens/schema/annotation_manager'

    # Set position configuration globally
    original_position = RailsLens.config.annotations[:position]
    RailsLens.config.annotations[:position] = :before

    model = @test_models.first
    file_path = @model_files[model]

    # Handle case where file path is not available
    flunk 'Model file path not available for this test environment - test setup is invalid' unless file_path

    # Create an annotation manager for this specific model
    manager = RailsLens::Schema::AnnotationManager.new(model)

    # Annotate the file
    manager.annotate_file(file_path)

    content = File.read(file_path)

    # Should be before the class definition
    class_position = content.index('class User')
    annotation_position = content.index('rails-lens:schema:begin')

    assert_not_nil annotation_position, 'Annotation should be present'
    assert_not_nil class_position, 'Class definition should be present'
    assert_operator annotation_position, :<, class_position,
                    "Annotation should appear before class definition when position is 'before'"
  ensure
    # Restore original position
    RailsLens.config.annotations[:position] = original_position
  end

  def test_annotation_handles_models_without_tables_gracefully
    require 'rails_lens/schema/annotation_manager'

    # Create a model without a table
    abstract_model_content = <<~RUBY
      class AbstractModel < ApplicationRecord
        self.abstract_class = true
      end
    RUBY

    abstract_path = File.join(@temp_models_dir, 'abstract_model.rb')
    File.write(abstract_path, abstract_model_content)

    config = {
      'models_path' => @temp_models_dir,
      'position' => 'after'
    }

    # This should not raise an error (allow up to 10 seconds for full app scan)
    Timeout.timeout(10) do
      assert_nothing_raised do
        # Use the class method directly
        RailsLens::Schema::AnnotationManager.annotate_all(config)
      end
    end
  end

  private

  def get_model_file_path(model)
    File.join(@temp_models_dir, "#{model.name.underscore}.rb")
  end
end
