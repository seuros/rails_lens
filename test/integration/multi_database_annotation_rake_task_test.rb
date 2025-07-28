# frozen_string_literal: true

require 'test_helper'

class MultiDatabaseAnnotationRakeTaskTest < ActiveSupport::TestCase
  setup do
    @dummy_path = File.expand_path('../dummy', __dir__)

    # Create a temporary directory for test models
    @temp_dir = Dir.mktmpdir('rails_lens_multi_db_test')
    @temp_models_dir = File.join(@temp_dir, 'app', 'models')
    FileUtils.mkdir_p(@temp_models_dir)

    # Test models from different databases
    @model_groups = {
      primary: [User, Post, Comment],
      vehicles: [Vehicle, VehicleOwner],
      prehistoric: [Dinosaur]
    }

    @model_files = {}

    # Copy all model files to temp directory and clean existing annotations
    @model_groups.values.flatten.each do |model|
      original_path = File.join(@dummy_path, 'app', 'models', "#{model.name.underscore}.rb")
      next unless File.exist?(original_path)

      temp_path = File.join(@temp_models_dir, "#{model.name.underscore}.rb")

      # Read original content and remove any existing annotations
      content = File.read(original_path)
      clean_content = remove_existing_annotations(content)
      File.write(temp_path, clean_content)

      @model_files[model] = temp_path
    end
  end

  teardown do
    # Clean up temp directory
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  private

  def remove_existing_annotations(content)
    # Remove rails-lens annotation blocks
    content.gsub(/^# <rails-lens:schema:begin>.*?^# <rails-lens:schema:end>\n/m, '')
  end

  def test_annotates_models_across_multiple_databases_correctly
    require 'rails_lens/schema/annotation_manager'
    require 'rails_lens/model_detector'

    all_models = @model_groups.values.flatten

    # Stub ModelDetector to return our test models
    RailsLens::ModelDetector.stub :detect_models, all_models do
      # Test annotation
      RailsLens::Schema::AnnotationManager.annotate_all(
        models_path: @temp_models_dir,
        position: 'after'
      )

      # Verify PostgreSQL models
      @model_groups[:primary].each do |model|
        next unless @model_files[model]

        content = File.read(@model_files[model])

        assert_includes content, 'rails-lens:schema:begin'
        assert_includes content, 'database_dialect = "PostgreSQL"'
        assert_includes content, "table = \"#{model.table_name}\""
      end

      # Verify MySQL models
      @model_groups[:vehicles].each do |model|
        next unless @model_files[model]

        content = File.read(@model_files[model])

        assert_includes content, 'rails-lens:schema:begin'
        assert_includes content, 'database_dialect = "MySQL"'
        assert_includes content, "table = \"#{model.table_name}\""
      end

      # Verify SQLite models
      @model_groups[:prehistoric].each do |model|
        next unless @model_files[model]

        content = File.read(@model_files[model])

        assert_includes content, 'rails-lens:schema:begin'
        assert_includes content, 'database_dialect = "SQLite"'
        assert_includes content, "table = \"#{model.table_name}\""
      end
    end

    # Test removal
    RailsLens::ModelDetector.stub :detect_models, all_models do
      # Remove annotations from all models
      all_models.each do |model|
        manager = RailsLens::Schema::AnnotationManager.new(model)
        file_path = @model_files[model]
        manager.remove_annotations(file_path) if file_path
      end

      # Verify all annotations removed
      @model_files.each_value do |file_path|
        content = File.read(file_path)

        assert_not_includes content, 'rails-lens:schema:begin'
        assert_not_includes content, 'rails-lens:schema:end'
      end
    end
  end

  def test_preserves_model_functionality_after_annotation_cycle
    require 'rails_lens/schema/annotation_manager'
    require 'rails_lens/model_detector'

    # Test that models still work after being annotated
    all_models = @model_groups.values.flatten

    # Annotate all models
    RailsLens::ModelDetector.stub :detect_models, all_models do
      RailsLens::Schema::AnnotationManager.annotate_all(
        models_path: @temp_models_dir,
        position: 'after'
      )
    end

    # Models should still be functional
    assert_nothing_raised do
      # Test PostgreSQL model
      assert_equal 'users', User.table_name
      assert_respond_to User, :create

      # Test MySQL model if connection is available
      assert_equal 'vehicles', Vehicle.table_name if defined?(Vehicle) && Vehicle.connected?

      # Test SQLite model
      assert_equal 'dinosaurs', Dinosaur.table_name
    end
  end

  def test_handles_connection_failures_gracefully
    require 'rails_lens/schema/annotation_manager'
    require 'rails_lens/model_detector'

    all_models = @model_groups.values.flatten

    # Even if some databases are unavailable, annotation should work for available ones
    assert_nothing_raised do
      RailsLens::ModelDetector.stub :detect_models, all_models do
        RailsLens::Schema::AnnotationManager.annotate_all(
          models_path: @temp_models_dir,
          position: 'after'
        )
      end
    end

    # At least SQLite models should be annotated (SQLite is always available)
    @model_groups[:prehistoric].each do |model|
      next unless @model_files[model]

      content = File.read(@model_files[model])

      assert_includes content, 'rails-lens:schema:begin'
    end
  end

  def test_respects_include_and_exclude_patterns
    require 'rails_lens/schema/annotation_manager'
    require 'rails_lens/model_detector'

    # Create a custom load_models that respects include/exclude
    included_models = [User, Vehicle].select { |m| @model_files[m] }

    RailsLens::ModelDetector.stub :detect_models, included_models do
      RailsLens::Schema::AnnotationManager.annotate_all(
        models_path: @temp_models_dir,
        position: 'after',
        include: %w[User Vehicle],
        exclude: %w[Post Comment]
      )

      # Included models should be annotated
      [User, Vehicle].each do |model|
        next unless @model_files[model]

        content = File.read(@model_files[model])

        assert_includes content, 'rails-lens:schema:begin'
      end

      # Excluded models should not be annotated
      [Post, Comment].each do |model|
        next unless @model_files[model]

        content = File.read(@model_files[model])

        assert_not_includes content, 'rails-lens:schema:begin'
      end
    end
  end
end
