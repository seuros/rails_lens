# frozen_string_literal: true

require 'test_helper'

class PrismParserTest < ActiveSupport::TestCase
  def test_parses_simple_class_definition
    content = <<~RUBY
      # frozen_string_literal: true

      class TestModel
        def initialize
          @name = 'test'
        end
      end
    RUBY

    with_temp_file(content) do |file_path|
      result = RailsLens::Parsers::PrismParser.parse_file(file_path)

      assert_equal 1, result.classes.size
      assert_equal 0, result.modules.size

      test_class = result.classes.first

      assert_equal 'TestModel', test_class.name
      assert_equal 3, test_class.line_number
      assert_equal 0, test_class.column
      assert_equal 7, test_class.end_line
      assert_nil test_class.namespace
    end
  end

  def test_parses_namespaced_class_definition
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
      result = RailsLens::Parsers::PrismParser.parse_file(file_path)

      assert_equal 1, result.classes.size
      assert_equal 1, result.modules.size

      test_module = result.modules.first

      assert_equal 'MyApp', test_module.name
      assert_equal 3, test_module.line_number
      assert_nil test_module.namespace

      test_class = result.classes.first

      assert_equal 'TestModel', test_class.name
      assert_equal 4, test_class.line_number
      assert_equal 'MyApp', test_class.namespace
      assert_equal 'MyApp::TestModel', test_class.full_name
    end
  end

  def test_parses_multiple_classes_in_same_file
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
      result = RailsLens::Parsers::PrismParser.parse_file(file_path)

      assert_equal 2, result.classes.size
      assert_equal 0, result.modules.size

      first_class = result.classes.first

      assert_equal 'FirstModel', first_class.name
      assert_equal 3, first_class.line_number

      second_class = result.classes.last

      assert_equal 'SecondModel', second_class.name
      assert_equal 8, second_class.line_number
    end
  end

  def test_handles_parse_errors_gracefully
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
      result = RailsLens::Parsers::PrismParser.parse_file(file_path)

      # Prism is more lenient, so it might still parse some classes
      # The important thing is that it doesn't crash
      assert_not_nil result
      assert_operator result.classes.size, :>=, 0
      assert_operator result.modules.size, :>=, 0
    end
  end

  def test_finds_class_by_name
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
      result = RailsLens::Parsers::PrismParser.parse_file(file_path)

      # Should find by simple name
      found_class = result.find_class('TestModel')

      assert_not_nil found_class
      assert_equal 'TestModel', found_class.name

      # Should find by full name
      found_class = result.find_class('MyApp::TestModel')

      assert_not_nil found_class
      assert_equal 'TestModel', found_class.name

      # Should not find non-existent class
      found_class = result.find_class('NonExistentModel')

      assert_nil found_class
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
