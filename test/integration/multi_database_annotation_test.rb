# frozen_string_literal: true

require 'test_helper'
require 'fileutils'

class MultiDatabaseAnnotationTest < ActiveSupport::TestCase
  def setup
    @test_output_dir = Rails.root.join('tmp/test_annotation')
    FileUtils.mkdir_p(@test_output_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_output_dir) if @test_output_dir
  end

  def test_annotate_models_across_all_databases
    # Create test files for models from each database
    test_files = {
      'user.rb' => User, # Primary database (PostgreSQL)
      'vehicle.rb' => Vehicle,         # Vehicles database (MySQL)
      'dinosaur.rb' => Dinosaur        # Prehistoric database (SQLite)
    }

    test_files.each do |filename, model_class|
      temp_file = @test_output_dir.join(filename)

      # Write a simple model file
      File.write(temp_file, <<~RUBY)
        # frozen_string_literal: true

        class #{model_class.name} < #{model_class.superclass.name}
        end
      RUBY

      # Generate annotation
      manager = RailsLens::Schema::AnnotationManager.new(model_class)
      annotation = manager.generate_annotation

      # Verify annotation contains database-specific information in TOML format
      assert_includes annotation, "table = \"#{model_class.table_name}\""

      # Get the proper dialect name
      dialect = case model_class.connection.adapter_name
                when /mysql2/i
                  'MySQL'
                when /postgresql/i
                  'PostgreSQL'
                when /sqlite/i
                  'SQLite'
                else
                  model_class.connection.adapter_name
                end

      assert_includes annotation, "database_dialect = \"#{dialect}\""
      assert_includes annotation, 'columns = ['

      # Verify adapter-specific information
      case model_class.connection.adapter_name
      when 'PostgreSQL'

        assert_includes annotation, 'database_dialect = "PostgreSQL"'
      when 'Mysql2'

        assert_includes annotation, 'database_dialect = "MySQL"'
      when 'SQLite'

        assert_includes annotation, 'database_dialect = "SQLite"'
      end
    end
  end

  def test_models_with_same_table_names_in_different_databases
    # Both User (PostgreSQL) and Owner (MySQL) could have similar table structures
    # Test that annotations are database-specific

    models_to_test = [
      { model: User, database: 'PostgreSQL' },
      { model: Owner, database: 'MySQL' }
    ]

    annotations = {}

    models_to_test.each do |config|
      model = config[:model]

      # Ensure model has proper connection before annotation
      begin
        # Test the connection
        assert_predicate model.connection, :active?, "#{model.name} connection should be active"
        assert_predicate model, :table_exists?, "#{model.name} table should exist in its database"
      rescue StandardError => e
        # Connection or table issues should be real test failures
        flunk "Failed to establish connection or verify table for #{model.name}: #{e.message}"
      end

      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation
      annotations[model.name] = annotation

      assert_not_empty annotation, "Annotation should not be empty for #{model.name}. Got: #{annotation.inspect}"
      assert_includes annotation, "database_dialect = \"#{config[:database]}\"",
                      "Expected #{config[:database]} dialect for #{model.name}. Got: #{annotation.inspect}"
      assert_includes annotation, "table = \"#{model.table_name}\"",
                      "Expected table info for #{model.name}. Got: #{annotation.inspect}"
    end

    # Ensure annotations are different despite potentially similar schemas
    assert_not_equal annotations['User'], annotations['Owner']
  end

  def test_annotate_abstract_classes
    # Test PrehistoricRecord (SQLite abstract class)
    abstract_classes = [PrehistoricRecord, VehicleRecord]

    abstract_classes.each do |abstract_class|
      manager = RailsLens::Schema::AnnotationManager.new(abstract_class)

      # Abstract classes can be annotated, but they only show database info
      annotation = manager.generate_annotation

      assert_not_empty annotation,
                       "Annotation should not be empty for abstract class #{abstract_class.name}. Got: #{annotation.inspect}"
      assert_includes annotation, 'database_dialect =',
                      "Expected database_dialect in annotation for #{abstract_class.name}. Got: #{annotation.inspect}"
      assert_includes annotation, 'abstract class',
                      "Expected 'abstract class' text in annotation for #{abstract_class.name}. Got: #{annotation.inspect}"
      assert_not_includes annotation, 'table =',
                          "Abstract class #{abstract_class.name} should not have table info. Got: #{annotation.inspect}"
      assert_not_includes annotation, 'columns =',
                          "Abstract class #{abstract_class.name} should not have columns info. Got: #{annotation.inspect}"
    end
  end

  def test_annotate_models_inheriting_from_abstract_classes
    # Test models that inherit from abstract classes
    inherited_models = {
      Dinosaur => PrehistoricRecord,
      Vehicle => VehicleRecord,
      ExcavationSite => PrehistoricRecord,
      Manufacturer => VehicleRecord
    }

    inherited_models.each_key do |model|
      # Ensure the model has a proper connection before proceeding

      # Try to establish connection if not already connected
      unless model.connected?
        # For models inheriting from abstract classes, ensure the abstract class connection is established
        abstract_parent = inherited_models[model]
        abstract_parent.connection if abstract_parent.respond_to?(:connection)
      end

      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Should include information about the database from abstract parent
      # Get the proper dialect name
      dialect = case model.connection.adapter_name
                when /mysql2/i
                  'MySQL'
                when /postgresql/i
                  'PostgreSQL'
                when /sqlite/i
                  'SQLite'
                else
                  model.connection.adapter_name
                end

      assert_not_empty annotation, "Annotation should not be empty for #{model.name}"
      assert_includes annotation, "table = \"#{model.table_name}\""
      assert_includes annotation, "database_dialect = \"#{dialect}\""
    rescue ActiveRecord::ConnectionNotDefined => e
      # Connection issues should be real test failures for models that should have connections
      flunk "Failed to establish connection for #{model.name}: #{e.message}"
    end
  end

  def test_batch_annotation_across_databases
    # Test annotating multiple models at once across different databases
    models = [User, Post, Vehicle, Manufacturer, Dinosaur, Species]
    annotations = {}

    models.each do |model|
      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotations[model.name] = manager.generate_annotation
    end

    # Verify each annotation contains correct database info
    assert_includes annotations['User'], 'database_dialect = "PostgreSQL"'
    assert_includes annotations['Post'], 'database_dialect = "PostgreSQL"'
    assert_includes annotations['Vehicle'], 'database_dialect = "MySQL"'
    assert_includes annotations['Manufacturer'], 'database_dialect = "MySQL"'
    assert_includes annotations['Dinosaur'], 'database_dialect = "SQLite"'
    assert_includes annotations['Species'], 'database_dialect = "SQLite"'
  end

  def test_connection_pool_management
    # Test that connection switching works properly during annotation
    initial_connections = ActiveRecord::Base.connection_handler.connection_pool_names

    # Annotate models from all databases
    [User, Vehicle, Dinosaur].each do |model|
      manager = RailsLens::Schema::AnnotationManager.new(model)
      manager.generate_annotation
    end

    # Ensure all connections are still available
    final_connections = ActiveRecord::Base.connection_handler.connection_pool_names

    assert_equal initial_connections.sort, final_connections.sort
  end

  def test_concurrent_annotation_across_databases
    # Test thread safety when annotating models from different databases
    results = {}
    errors = []
    models = [User, Post, Vehicle, Manufacturer, Dinosaur, Species]

    threads = models.map do |model|
      Thread.new do
        manager = RailsLens::Schema::AnnotationManager.new(model)
        results[model.name] = manager.generate_annotation
      rescue StandardError => e
        errors << { model: model.name, error: e.message }
      end
    end

    threads.each(&:join)

    # All models should have been annotated successfully
    assert_empty errors
    assert_equal models.size, results.size

    # Each annotation should be correct for its database
    results.each_value do |annotation|
      assert_includes annotation, 'table = '
      assert_includes annotation, 'database_dialect = '
      assert_includes annotation, 'columns = ['
    end
  end
end
