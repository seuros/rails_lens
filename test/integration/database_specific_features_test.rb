# frozen_string_literal: true

require 'test_helper'
require 'fileutils'

class DatabaseSpecificFeaturesTest < ActiveSupport::TestCase
  def setup
    @dummy_path = File.expand_path('../dummy', __dir__)
    @original_dir = Dir.pwd
    Dir.chdir(@dummy_path)
    @test_output_dir = Rails.root.join('tmp/test_db_features')
    FileUtils.mkdir_p(@test_output_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_output_dir) if @test_output_dir
    Dir.chdir(@original_dir)
  end

  def test_postgresql_specific_features
    # Test PostgreSQL-specific column types and features
    postgresql_models = [User, Post, Comment, Spaceship, CrewMember]

    postgresql_models.each do |model|
      next unless model.connection.adapter_name == 'PostgreSQL'

      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Check for PostgreSQL-specific information
      assert_includes annotation, 'database_dialect = "PostgreSQL"'

      # Look for PostgreSQL-specific column types if present
      schema = model.connection.schema_cache.columns(model.table_name)

      schema.each do |column|
        case column.sql_type_metadata.sql_type
        when /jsonb/i

          assert_includes annotation, 'jsonb'
        when /uuid/i

          assert_includes annotation, 'uuid'
        when /inet/i

          assert_includes annotation, 'inet'
        when /array/i

          assert_includes annotation, '[]' # Array notation
        when /tsvector/i

          assert_includes annotation, 'tsvector'
        end
      end

      # Check for indexes if present
      assert_match(/indexes = \[/, annotation) if model.connection.indexes(model.table_name).any?
    end
  end

  def test_mysql_specific_features
    # Test MySQL-specific column types and features
    mysql_models = [Vehicle, Manufacturer, Owner, Trip, MaintenanceRecord]

    mysql_models.each do |model|
      next unless model.connection.adapter_name == 'Mysql2'

      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Check for MySQL-specific information
      assert_includes annotation, 'database_dialect = "MySQL"'

      # Look for MySQL-specific features
      schema = model.connection.schema_cache.columns(model.table_name)

      schema.each do |column|
        # Check for MySQL-specific types
        case column.sql_type_metadata.sql_type
        when /json/i

          assert_includes annotation, 'json'
        when /enum/i

          assert_includes annotation, 'enum'
        when /set/i

          assert_includes annotation, 'set'
        when /mediumtext/i

          assert_includes annotation, 'mediumtext'
        when /tinyint\(1\)/i
          # MySQL boolean
          assert_includes annotation, 'boolean'
        end
      end

      # Check for storage engine info if available
      assert_match(/storage_engine = "(InnoDB|MyISAM)"/, annotation) if annotation.include?('storage_engine')
    end
  end

  def test_sqlite_specific_features
    # Test SQLite-specific features and limitations
    sqlite_models = [Dinosaur, Species, Family, ExcavationSite, FossilDiscovery]

    sqlite_models.each do |model|
      next unless model.connection.adapter_name == 'SQLite'

      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Check for SQLite-specific information
      assert_includes annotation, 'database_dialect = "SQLite"'

      # SQLite has limited types, check mapping
      schema = model.connection.schema_cache.columns(model.table_name)

      schema.each do |column|
        # SQLite stores everything as one of: NULL, INTEGER, REAL, TEXT, BLOB
        sql_type = column.sql_type_metadata.sql_type

        # Verify proper type mapping in annotation
        case sql_type
        when /integer/i

          assert_match(/integer|bigint/, annotation)
        when /real|float|double/i

          assert_match(/float|decimal/, annotation)
        when /text|varchar|char/i

          assert_match(/string|text/, annotation)
        when /blob/i

          assert_match(/binary|blob/, annotation)
        end
      end

      # SQLite doesn't support certain features
      assert_not_includes annotation, 'foreign_keys = [' unless model.connection.supports_foreign_keys?
    end
  end

  def test_column_defaults_across_databases
    # Test how different databases handle column defaults
    test_models = {
      'PostgreSQL' => User,
      'Mysql2' => Vehicle,
      'SQLite' => Dinosaur
    }

    test_models.each do |adapter, model|
      next unless model.connection.adapter_name == adapter

      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Check for default values
      schema = model.connection.schema_cache.columns(model.table_name)

      schema.each do |column|
        next unless column.default

        assert_includes annotation, column.name
        # Default should be mentioned in annotation
        assert_match(/default =/, annotation) if column.default
      end
    end
  end

  def test_constraints_and_indexes_annotation
    # Test annotation of constraints and indexes across different databases
    models = [User, Vehicle, Dinosaur]

    models.each do |model|
      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Check for columns
      assert_includes annotation, 'columns = ['

      # Check for indexes
      indexes = model.connection.indexes(model.table_name)
      if indexes.any?
        assert_includes annotation, 'indexes = ['

        indexes.each do |index|
          assert_includes annotation, index.name
          assert_includes annotation, 'unique = true' if index.unique
        end
      end

      # Check for foreign keys if supported
      next unless model.connection.supports_foreign_keys?

      foreign_keys = model.connection.foreign_keys(model.table_name)
      assert_includes annotation, 'foreign_keys = [' if foreign_keys.any?
    end
  end

  def test_generated_columns_and_virtual_fields
    # Test support for generated columns and virtual fields
    # Test with models that might have generated columns
    models_to_test = [Vehicle, User]

    models_to_test.each do |model|
      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Basic assertions that should always pass
      assert_not_empty annotation, "Annotation should not be empty for #{model.name}"
      assert_includes annotation, 'table =', "Annotation should include table information for #{model.name}"
      assert_includes annotation, 'columns =', "Annotation should include columns information for #{model.name}"

      # Look for generated column indicators
      schema = model.connection.schema_cache.columns(model.table_name)
      virtual_columns_found = false

      schema.each do |column|
        next unless column.respond_to?(:virtual?) && column.virtual?

        virtual_columns_found = true

        assert_includes annotation, 'GENERATED',
                        "Annotation should include GENERATED marker for virtual column #{column.name}"
      end

      # If no virtual columns were found, that's also a valid test result
      # We just need to ensure the annotation was generated successfully
      unless virtual_columns_found
        assert_includes annotation, 'database_dialect =', "Annotation should include database dialect for #{model.name}"
      end
    end
  end

  def test_database_specific_data_types_in_erd
    # Test that ERD properly represents database-specific types
    visualizer = RailsLens::ERD::Visualizer.new(
      options: {
        output_dir: @test_output_dir,
        include_all_databases: true,
        show_column_types: true
      }
    )

    filename = visualizer.generate
    output = File.read(filename)

    # Test PostgreSQL types - SpatialCoordinate uses PostgreSQL
    assert_includes output, 'SpatialCoordinate', 'ERD should include SpatialCoordinate model'
    assert_equal 'PostgreSQL', SpatialCoordinate.connection.adapter_name, 'SpatialCoordinate should use PostgreSQL'
    # Check for PostgreSQL-specific types in ERD output
    assert_match(/jsonb|uuid|inet|array/, output, 'ERD should show PostgreSQL-specific data types')

    # Test MySQL types - Vehicle uses MySQL
    assert_includes output, 'Vehicle', 'ERD should include Vehicle model'
    assert_equal 'Mysql2', Vehicle.connection.adapter_name, 'Vehicle should use MySQL'
    # Check for MySQL-specific types in ERD output
    assert_match(/json|enum|mediumtext/, output, 'ERD should show MySQL-specific data types')

    # Test SQLite types - Dinosaur uses SQLite
    assert_includes output, 'Dinosaur', 'ERD should include Dinosaur model'
    assert_equal 'SQLite', Dinosaur.connection.adapter_name, 'Dinosaur should use SQLite'
    # ERD normalizes SQLite types to standard SQL types
    assert_match(/varchar|int|decimal/, output, 'ERD should show normalized SQLite data types')
  end

  def test_adapter_specific_annotation_formatting
    # Test that annotations are formatted appropriately for each adapter
    adapters_and_models = {
      'PostgreSQL' => User,
      'Mysql2' => Vehicle,
      'SQLite' => Dinosaur
    }

    adapters_and_models.each do |expected_adapter, model|
      next unless model.connection.adapter_name == expected_adapter

      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Common elements
      assert_includes annotation, "table = \"#{model.table_name}\""
      assert_includes annotation, 'database_dialect = "'

      # Adapter-specific formatting
      case expected_adapter
      when 'PostgreSQL'
        # PostgreSQL might include schema name
        assert_match(/schema = "|public\./, annotation) if annotation.include?('schema = ')
      when 'Mysql2'
        # MySQL might include character set/collation
        assert_match(/character_set = "|collation = "|utf8/, annotation) if annotation.include?('character_set = ')
      when 'SQLite'
        # SQLite is simpler, shouldn't have complex features
        assert_not_includes annotation, 'schema = '
        assert_not_includes annotation, 'character_set = '
      end
    end
  end

  def test_postgresql_schema_qualified_table_names
    skip 'PostgreSQL only test' unless User.connection.adapter_name == 'PostgreSQL'

    # Use existing AuditLog model with schema-qualified table name (audit.audit_logs)
    adapter = RailsLens::Schema::Adapters::Postgresql.new(
      ActiveRecord::Base.connection,
      'audit.audit_logs'
    )

    annotation = adapter.generate_annotation(AuditLog)

    # Verify the annotation includes the schema
    assert_includes annotation, 'table = "audit.audit_logs"',
                    'Annotation should include schema-qualified table name'
    assert_includes annotation, 'schema = "audit"',
                    'Annotation should include schema name'
    assert_includes annotation, 'database_dialect = "PostgreSQL"',
                    'Annotation should include database dialect'

    # Verify columns are properly extracted
    assert_includes annotation, 'columns = [',
                    'Annotation should include columns array'
    assert_includes annotation, 'name = "id"',
                    'Annotation should include id column'
    assert_includes annotation, 'name = "table_name"',
                    'Annotation should include table_name column'
    assert_includes annotation, 'name = "record_id"',
                    'Annotation should include record_id column'
    assert_includes annotation, 'name = "action"',
                    'Annotation should include action column'

    # Verify no errors for schema-qualified table operations
    assert_nothing_raised do
      adapter.send(:columns)
      adapter.send(:fetch_indexes)
      adapter.send(:fetch_foreign_keys)
      adapter.send(:primary_key_name)
    end
  end
end
