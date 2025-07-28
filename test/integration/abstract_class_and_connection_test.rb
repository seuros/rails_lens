# frozen_string_literal: true

require 'test_helper'
require 'fileutils'

class AbstractClassAndConnectionTest < ActiveSupport::TestCase
  def setup
    # Use a temp directory for test output instead of modifying the dummy app
    @test_output_dir = Dir.mktmpdir('rails_lens_abstract_test')
  end

  def teardown
    FileUtils.rm_rf(@test_output_dir) if @test_output_dir && File.exist?(@test_output_dir)
  end

  def test_rails_lens_skips_abstract_classes
    # Test that RailsLens properly skips abstract classes during model detection
    # Get all detected models
    detected_models = RailsLens::ModelDetector.detect_models

    # Abstract classes should not be included in detected models
    abstract_classes = [ApplicationRecord, PrehistoricRecord, VehicleRecord]

    abstract_classes.each do |abstract_class|
      assert_not_includes detected_models, abstract_class,
                          "RailsLens should skip abstract class #{abstract_class.name}"
    end

    # But concrete classes should be included
    concrete_classes = [User, Vehicle, Dinosaur]

    concrete_classes.each do |concrete_class|
      assert_includes detected_models, concrete_class,
                      "RailsLens should include concrete class #{concrete_class.name}"
    end
  end

  def test_concrete_class_inheritance_from_abstract
    # Test concrete classes inherit properly from abstract classes
    inheritance_map = {
      ApplicationRecord => [User, Post, Comment, Alert, Announcement, Entry],
      PrehistoricRecord => [Dinosaur, Species, Family, ExcavationSite, FossilDiscovery],
      VehicleRecord => [Vehicle, Manufacturer, Owner, Trip, MaintenanceRecord]
    }

    inheritance_map.each do |abstract_class, concrete_classes|
      concrete_classes.each do |concrete_class|
        # Verify inheritance
        assert_operator concrete_class, :<, abstract_class,
                        "#{concrete_class.name} should inherit from #{abstract_class.name}"

        # Verify it's not abstract
        assert_not concrete_class.abstract_class?,
                   "#{concrete_class.name} should not be abstract"

        # Verify it has a table name
        assert_predicate concrete_class.table_name, :present?,
                         "#{concrete_class.name} should have a table name"
      end
    end
  end

  def test_connection_routing_through_abstract_classes
    # Test that connections are properly routed through abstract classes
    connection_tests = [
      { model: Dinosaur, expected_db: 'prehistoric', adapter: 'SQLite' },
      { model: Vehicle, expected_db: 'vehicles', adapter: 'Mysql2' },
      { model: User, expected_db: 'primary', adapter: 'PostgreSQL' }
    ]

    connection_tests.each do |test|
      model = test[:model]

      # Verify connection configuration
      assert_equal test[:expected_db], model.connection_db_config.name
      assert_equal test[:adapter], model.connection.adapter_name

      # Verify we can actually query the database
      assert_predicate model.connection, :active?, "#{model.name} connection should be active"
    end
  end

  def test_annotation_with_abstract_class_hierarchy
    # Test annotating models with complex inheritance hierarchies
    models_to_annotate = [
      # Direct ApplicationRecord descendants
      User,
      # PrehistoricRecord descendants
      Dinosaur,
      Species,
      # VehicleRecord descendants
      Vehicle,
      Manufacturer
    ]

    models_to_annotate.each do |model|
      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Should include correct database in TOML format
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

      assert_includes annotation, "database_dialect = \"#{dialect}\""

      # Should have table information
      assert_includes annotation, 'table = '
    end
  end

  def test_erd_generation_with_abstract_classes
    # Test ERD generation handles abstract classes correctly
    visualizer = RailsLens::ERD::Visualizer.new(
      options: {
        output_dir: @test_output_dir,
        include_all_databases: true,
        show_inheritance: true
      }
    )

    filename = visualizer.generate
    output = File.read(filename)

    # Should not include abstract classes as entities
    assert_not_includes output, 'PrehistoricRecord {{'
    assert_not_includes output, 'VehicleRecord {{'
    assert_not_includes output, 'ApplicationRecord {{'

    # But should include concrete classes
    assert_includes output, 'Dinosaur'
    assert_includes output, 'Vehicle'
    assert_includes output, 'User'

    # Abstract classes should not be included in ERD output since ModelDetector excludes them
    assert_not_includes output, 'PrehistoricRecord', 'ERD should not include PrehistoricRecord abstract class'
    assert_not_includes output, 'VehicleRecord', 'ERD should not include VehicleRecord abstract class'
  end

  def test_connection_pool_isolation
    # Test that connection pools are properly isolated between databases
    pools = {}

    # Get connection pools for each database
    [User, Vehicle, Dinosaur].each do |model|
      pool = model.connection_pool
      pools[model.connection_db_config.name] = pool
    end

    # Verify pools are different
    assert_equal 3, pools.values.uniq.size, 'Should have 3 distinct connection pools'

    # Verify each pool connects to the right database
    pools.each do |db_name, pool|
      pool.with_connection do |connection|
        case db_name
        when 'primary'

          assert_equal 'PostgreSQL', connection.adapter_name
        when 'vehicles'

          assert_equal 'Mysql2', connection.adapter_name
        when 'prehistoric'

          assert_equal 'SQLite', connection.adapter_name
        end
      end
    end
  end

  def test_connection_switching_during_annotation
    # Test that we can switch between connections during batch annotation
    connection_log = []

    models = [User, Vehicle, Dinosaur, Post, Manufacturer, Species]

    models.each do |model|
      current_db = model.connection_db_config.name
      connection_log << current_db

      # Annotate the model
      manager = RailsLens::Schema::AnnotationManager.new(model)
      manager.generate_annotation

      # Verify we're still on the right connection
      assert_equal current_db, model.connection_db_config.name
    end

    # Verify we switched between databases
    unique_dbs = connection_log.uniq

    assert_equal 3, unique_dbs.size, 'Should have connected to all 3 databases'
    assert_includes unique_dbs, 'primary'
    assert_includes unique_dbs, 'vehicles'
    assert_includes unique_dbs, 'prehistoric'
  end

  def test_parallel_access_to_multiple_databases
    # Test concurrent access to multiple databases
    results = Concurrent::Hash.new
    errors = Concurrent::Array.new

    # Create threads for parallel access
    threads = []

    # Multiple models from each database
    models_per_db = {
      'primary' => [User, Post, Comment, Spaceship, CrewMember],
      'vehicles' => [Vehicle, Manufacturer, Owner, Trip, MaintenanceRecord],
      'prehistoric' => [Dinosaur, Species, Family, ExcavationSite, FossilDiscovery]
    }

    models_per_db.each_value do |models|
      models.each do |model|
        threads << Thread.new do
          # Perform database operations
          count = model.count
          first_record = model.first
          connection_name = model.connection_db_config.name

          results[model.name] = {
            count: count,
            has_records: !first_record.nil?,
            database: connection_name
          }
        rescue StandardError => e
          errors << { model: model.name, error: e.message }
        end
      end
    end

    # Wait for all threads to complete
    threads.each(&:join)

    # Verify no errors occurred
    assert_empty errors, "Errors occurred: #{errors.inspect}"

    # Verify all models were accessed
    assert_equal 15, results.size

    # Verify correct database assignment
    results.each do |model_name, info|
      case info[:database]
      when 'primary'

        assert_includes models_per_db['primary'].map(&:name), model_name
      when 'vehicles'

        assert_includes models_per_db['vehicles'].map(&:name), model_name
      when 'prehistoric'

        assert_includes models_per_db['prehistoric'].map(&:name), model_name
      end
    end
  end

  def test_abstract_class_connection_specification
    # Test that abstract classes properly specify connections
    abstract_specs = {
      PrehistoricRecord => 'prehistoric',
      VehicleRecord => 'vehicles'
    }

    abstract_specs.each do |abstract_class, expected_db|
      # Get a concrete subclass to test connection
      concrete_model = abstract_class.descendants.reject(&:abstract_class?).first

      assert concrete_model, "Should have concrete descendants for #{abstract_class.name}"
      assert_equal expected_db, concrete_model.connection_db_config.name
    end
  end

  def test_connection_handler_state_consistency
    # Test that connection handler maintains consistent state
    handler = ActiveRecord::Base.connection_handler

    # Get initial state
    initial_pools = handler.connection_pool_names.sort

    # Perform various operations
    [User, Vehicle, Dinosaur].each do |model|
      model.connection.active?
      model.connection_pool.stat
    end

    # Run annotation across databases
    models = [User, Post, Vehicle, Manufacturer, Dinosaur, Species]
    models.each do |model|
      manager = RailsLens::Schema::AnnotationManager.new(model)
      manager.generate_annotation
    end

    # Verify state is consistent
    final_pools = handler.connection_pool_names.sort

    assert_equal initial_pools, final_pools, 'Connection pools should remain consistent'
  end
end
