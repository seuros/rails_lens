# frozen_string_literal: true

require 'test_helper'

class FileInsertionHelperTest < ActiveSupport::TestCase
  def test_inserts_at_class_definition
    content = <<~RUBY
      # frozen_string_literal: true

      class TestModel
        def initialize
          @name = 'test'
        end
      end
    RUBY

    with_temp_file(content) do |file_path|
      annotation = '# Test annotation'

      success = RailsLens::FileInsertionHelper.insert_at_class_definition(
        file_path,
        'TestModel',
        annotation
      )

      assert success

      result_content = File.read(file_path)

      assert_includes result_content, annotation

      # Should be inserted after frozen_string_literal with proper spacing
      lines = result_content.split("\n")

      assert_equal '# frozen_string_literal: true', lines[0]
      assert_equal '', lines[1]
      assert_equal '# Test annotation', lines[2]
      assert_equal 'class TestModel', lines[3]
    end
  end

  def test_inserts_at_namespaced_class_definition
    content = <<~RUBY
      # frozen_string_literal: true

      module MyApp
        class TestModel
          def initialize
            @name = 'test'
          end
        end
      end
    RUBY

    with_temp_file(content) do |file_path|
      annotation = '# Test annotation'

      success = RailsLens::FileInsertionHelper.insert_at_class_definition(
        file_path,
        'TestModel',
        annotation
      )

      assert success

      result_content = File.read(file_path)

      assert_includes result_content, annotation

      # Should be inserted after frozen_string_literal, not before class
      lines = result_content.split("\n")

      assert_equal '# frozen_string_literal: true', lines[0]
      assert_equal '', lines[1]
      assert_equal '# Test annotation', lines[2]
      assert_equal 'module MyApp', lines[3]
      assert_equal '  class TestModel', lines[4]
    end
  end

  def test_handles_multiple_classes_correctly
    content = <<~RUBY
      # frozen_string_literal: true

      class FirstModel
        def method1
        end
      end

      class SecondModel
        def method2
        end
      end
    RUBY

    with_temp_file(content) do |file_path|
      annotation = '# Test annotation'

      success = RailsLens::FileInsertionHelper.insert_at_class_definition(
        file_path,
        'SecondModel',
        annotation
      )

      assert success

      result_content = File.read(file_path)

      assert_includes result_content, annotation

      # Should be inserted after frozen_string_literal, not before SecondModel
      lines = result_content.split("\n")

      assert_equal '# frozen_string_literal: true', lines[0]
      assert_equal '', lines[1]
      assert_equal '# Test annotation', lines[2]
      assert_equal 'class FirstModel', lines[3]
    end
  end

  def test_falls_back_to_old_behavior_on_parse_errors
    content = <<~RUBY
      # frozen_string_literal: true

      class TestModel
        def broken_method
          if true
            puts "missing end"
        end
      end
    RUBY

    with_temp_file(content) do |file_path|
      annotation = '# Test annotation'

      RailsLens::FileInsertionHelper.insert_at_class_definition(
        file_path,
        'TestModel',
        annotation
      )

      # Prism is more lenient, so it might still succeed
      # The important thing is that the annotation is inserted
      result_content = File.read(file_path)

      assert_includes result_content, annotation
    end
  end

  def test_handles_file_without_frozen_string_literal
    content = <<~RUBY
      class TestModel
        def initialize
          @name = 'test'
        end
      end
    RUBY

    with_temp_file(content) do |file_path|
      annotation = '# Test annotation'

      success = RailsLens::FileInsertionHelper.insert_at_class_definition(
        file_path,
        'TestModel',
        annotation
      )

      assert success

      result_content = File.read(file_path)

      assert_includes result_content, annotation

      # Should be inserted directly before class
      lines = result_content.split("\n")

      assert_equal '# Test annotation', lines[0]
      assert_equal 'class TestModel', lines[1]
    end
  end

  def test_insert_at_class_definition_returns_false_when_content_is_unchanged
    annotation = <<~ANNOTATION.chomp
      # <rails-lens:schema:begin>
      # table = "test_models"
      # <rails-lens:schema:end>
    ANNOTATION

    content = <<~RUBY
      # frozen_string_literal: true

      #{annotation}
      class TestModel
      end
    RUBY

    with_temp_file(content) do |file_path|
      success = RailsLens::FileInsertionHelper.insert_at_class_definition(
        file_path,
        'TestModel',
        annotation
      )

      assert_not success
      assert_equal content, File.read(file_path)
    end
  end

  # Re-inserting an extension annotation (a non-schema "rails-lens:*" marker)
  # must replace the existing block, not stack a duplicate one.
  def test_reinserting_extension_annotation_replaces_existing_block
    annotation = "# <rails-lens:graph:begin>\n# model_type = \"node\"\n# <rails-lens:graph:end>"
    content = <<~RUBY
      # frozen_string_literal: true

      #{annotation}
      class WidgetNode
      end
    RUBY

    with_temp_file(content) do |file_path|
      updated = "# <rails-lens:graph:begin>\n# model_type = \"node\"\n# labels = [\"Widget\"]\n# <rails-lens:graph:end>"

      success = RailsLens::FileInsertionHelper.insert_at_class_definition(file_path, 'WidgetNode', updated)

      assert success

      result = File.read(file_path)

      assert_equal 1, result.scan('<rails-lens:graph:begin>').size, 'should not stack duplicate graph blocks'
      assert_includes result, 'labels = ["Widget"]'
    end
  end

  def test_reinserting_schema_annotation_replaces_existing_block
    annotation = "# <rails-lens:schema:begin>\n# old\n# <rails-lens:schema:end>"
    content = <<~RUBY
      # frozen_string_literal: true

      #{annotation}
      class TestModel
      end
    RUBY

    with_temp_file(content) do |file_path|
      updated = "# <rails-lens:schema:begin>\n# new\n# <rails-lens:schema:end>"

      RailsLens::FileInsertionHelper.insert_at_class_definition(file_path, 'TestModel', updated)

      result = File.read(file_path)

      assert_equal 1, result.scan('<rails-lens:schema:begin>').size
      assert_includes result, '# new'
      assert_not_includes result, '# old'
    end
  end

  private

  def with_temp_file(content)
    file = Tempfile.new(['test', '.rb'])
    file.write(content)
    file.close
    yield file.path
  ensure
    file&.unlink
  end
end
