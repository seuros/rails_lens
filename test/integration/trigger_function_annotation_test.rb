# frozen_string_literal: true

require 'test_helper'

class TriggerFunctionAnnotationTest < ActiveSupport::TestCase
  def setup
    @dummy_path = File.expand_path('../dummy', __dir__)
    @original_dir = Dir.pwd
    Dir.chdir(@dummy_path)
  end

  def teardown
    Dir.chdir(@original_dir)
  end

  # Comment < ApplicationRecord → PostgreSQL (static binding)
  def test_comment_model_includes_trigger_annotations
    manager = RailsLens::Schema::AnnotationManager.new(Comment)
    annotation = manager.generate_annotation

    # Verify triggers section exists
    assert_includes annotation, 'triggers = ['

    # Verify all 3 triggers from migration
    assert_includes annotation, 'increment_posts_comments_count'
    assert_includes annotation, 'decrement_posts_comments_count'
    assert_includes annotation, 'update_posts_comments_count_on_reassign'

    # Verify trigger attributes
    assert_includes annotation, 'event = "INSERT"'
    assert_includes annotation, 'event = "DELETE"'
    assert_includes annotation, 'event = "UPDATE"'
    assert_includes annotation, 'timing = "AFTER"'
    assert_includes annotation, 'function = "update_posts_comments_count"'
  end

  # ApplicationRecord → PostgreSQL (static binding)
  def test_application_record_includes_function_annotations
    annotator = RailsLens::Schema::DatabaseAnnotator.new(ApplicationRecord)
    annotation = annotator.generate_annotation

    # Verify functions section exists
    assert_includes annotation, '== Database Functions'
    assert_includes annotation, 'functions = ['

    # Verify the trigger function from migration
    assert_includes annotation, 'update_posts_comments_count'
    assert_includes annotation, 'language = "plpgsql"'
    assert_includes annotation, 'return_type = "trigger"'
  end

  def test_trigger_annotation_format_is_valid_toml
    manager = RailsLens::Schema::AnnotationManager.new(Comment)
    annotation = manager.generate_annotation

    # Extract triggers block
    triggers_match = annotation.match(/triggers = \[(.*?)\]/m)

    assert triggers_match, 'Should have triggers array'

    triggers_block = triggers_match[1]

    # Count trigger entries (each { } is one trigger)
    trigger_count = triggers_block.scan(/\{[^}]+\}/).count

    assert_equal 3, trigger_count, 'Should have exactly 3 triggers from migration'
  end

  def test_excludes_extension_owned_triggers
    adapter = RailsLens::Schema::Adapters::Postgresql.new(
      Comment.connection,
      'comments'
    )

    triggers = adapter.fetch_triggers

    # All triggers should be user-defined, not extension-owned
    triggers.each do |trigger|
      assert_predicate trigger[:name], :present?, 'Trigger should have a name'
      assert_not trigger[:name].start_with?('pg_'), 'Should not include pg_ internal triggers'
    end
  end

  # ===== MySQL Tests =====
  # MaintenanceRecord < VehicleRecord → MySQL (static binding)

  def test_maintenance_record_model_includes_trigger_annotations
    manager = RailsLens::Schema::AnnotationManager.new(MaintenanceRecord)
    annotation = manager.generate_annotation

    # Verify triggers section exists
    assert_includes annotation, 'triggers = ['

    # Verify triggers from migration
    assert_includes annotation, 'increment_vehicle_maintenance_count'
    assert_includes annotation, 'decrement_vehicle_maintenance_count'

    # Verify trigger attributes
    assert_includes annotation, 'event = "INSERT"'
    assert_includes annotation, 'event = "DELETE"'
    assert_includes annotation, 'timing = "AFTER"'
  end

  def test_mysql_trigger_annotation_format_is_valid_toml
    manager = RailsLens::Schema::AnnotationManager.new(MaintenanceRecord)
    annotation = manager.generate_annotation

    # Extract triggers block
    triggers_match = annotation.match(/triggers = \[(.*?)\]/m)

    assert triggers_match, 'Should have triggers array'

    triggers_block = triggers_match[1]

    # Count trigger entries (each { } is one trigger)
    trigger_count = triggers_block.scan(/\{[^}]+\}/).count

    assert_equal 2, trigger_count, 'Should have exactly 2 triggers from migration'
  end

  def test_mysql_adapter_fetches_triggers
    adapter = RailsLens::Schema::Adapters::Mysql.new(
      MaintenanceRecord.connection,
      'maintenance_records'
    )

    triggers = adapter.fetch_triggers

    # Verify we got the expected triggers
    trigger_names = triggers.pluck(:name)

    assert_includes trigger_names, 'increment_vehicle_maintenance_count'
    assert_includes trigger_names, 'decrement_vehicle_maintenance_count'

    # Verify trigger structure
    triggers.each do |trigger|
      assert_predicate trigger[:name], :present?, 'Trigger should have a name'
      assert_predicate trigger[:timing], :present?, 'Trigger should have timing'
      assert_predicate trigger[:event], :present?, 'Trigger should have event'
    end
  end
end
