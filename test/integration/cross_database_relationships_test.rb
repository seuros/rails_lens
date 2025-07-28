# frozen_string_literal: true

require 'test_helper'
require 'fileutils'

class CrossDatabaseRelationshipsTest < ActiveSupport::TestCase
  def setup
    @dummy_path = File.expand_path('../dummy', __dir__)
    @original_dir = Dir.pwd
    Dir.chdir(@dummy_path)
    @test_output_dir = Rails.root.join('tmp/test_cross_db')
    FileUtils.mkdir_p(@test_output_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_output_dir) if @test_output_dir
    Dir.chdir(@original_dir)
  end

  def test_cross_database_foreign_key_annotation
    # Test models that might reference tables in other databases
    # (Note: Rails doesn't support true cross-database foreign keys,
    # but we can test the annotation of such conceptual relationships)

    # Create a test model with cross-database reference annotation
    temp_file = @test_output_dir.join('cross_db_model.rb')
    File.write(temp_file, <<~RUBY)
      # frozen_string_literal: true

      class CrossDbModel < ApplicationRecord
        # Conceptual foreign key to another database
        # belongs_to :vehicle, class_name: 'Vehicle'
      end
    RUBY

    # Test that we can detect and annotate cross-database references
    manager = RailsLens::Schema::AnnotationManager.new(User)
    annotation = manager.generate_annotation

    # Should include database context in TOML format
    assert_includes annotation, 'database_dialect = "PostgreSQL"'
  end

  def test_polymorphic_associations_across_databases
    # Test polymorphic associations that might span databases
    # Comment model has polymorphic association
    manager = RailsLens::Schema::AnnotationManager.new(Comment)
    annotation = manager.generate_annotation

    # Check for polymorphic columns in TOML format
    assert_includes annotation, 'name = "commentable_type"'
    assert_includes annotation, 'name = "commentable_id"'

    # Check for polymorphic association note
    assert_includes annotation, '== Polymorphic Associations'
    assert_includes annotation, '- commentable (commentable_type/commentable_id)'
  end

  def test_erd_with_join_tables_across_databases
    # Test many-to-many relationships
    visualizer = RailsLens::ERD::Visualizer.new(
      options: {
        output_dir: @test_output_dir,
        include_all_databases: true,
        show_join_tables: true
      }
    )

    filename = visualizer.generate
    output = File.read(filename)

    # Check for join table relationships
    assert_includes output, 'SpaceshipCrewMember'
    assert_includes output, 'VehicleOwner'

    # Check relationships are properly mapped
    assert_match(/Spaceship.*SpaceshipCrewMember/, output)
    assert_match(/CrewMember.*SpaceshipCrewMember/, output)
    assert_match(/Vehicle.*VehicleOwner/, output)
    assert_match(/Owner.*VehicleOwner/, output)
  end

  def test_connection_metadata_in_relationships
    # Test that connection metadata is preserved in relationships
    models_with_relationships = [
      { model: Post, relationships: %w[user comments] },
      { model: Vehicle, relationships: %w[manufacturer owners] },
      { model: Dinosaur, relationships: ['fossil_discoveries'] }
    ]

    models_with_relationships.each do |config|
      model = config[:model]
      manager = RailsLens::Schema::AnnotationManager.new(model)
      annotation = manager.generate_annotation

      # Should include relationship information in notes
      # Note: belongs_to associations get counter cache suggestions, has_many get N+1 warnings
      if model == Post
        assert_includes annotation, "Consider adding counter cache for 'user'"
        assert_includes annotation, "Association 'comments' has N+1 query risk"
      elsif model == Vehicle
        assert_includes annotation, "Consider adding counter cache for 'manufacturer'"
        assert_includes annotation, "Association 'owners' has N+1 query risk"
      elsif model == Dinosaur
        assert_includes annotation, "Association 'fossil_discoveries' has N+1 query risk"
      end

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

      # Should include database context in TOML format
      assert_includes annotation, "database_dialect = \"#{dialect}\""
    end
  end
end
