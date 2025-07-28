# frozen_string_literal: true

require 'test_helper'

class PracticalAnnotationTest < ActiveSupport::TestCase
  def test_demonstrates_precise_annotation_placement_in_complex_file
    # Create a complex file with multiple classes
    complex_content = <<~RUBY
      # frozen_string_literal: true

      module Admin
        class BaseModel < ApplicationRecord
          self.abstract_class = true

          def admin_method
            "base admin method"
          end
        end

        class UserModel < BaseModel
          def user_specific_method
            "user method"
          end
        end
      end

      class RegularModel < ApplicationRecord
        belongs_to :user_model, class_name: 'Admin::UserModel'

        def regular_method
          "regular method"
        end
      end

      class AnotherModel < ApplicationRecord
        has_many :regular_models

        def another_method
          "another method"
        end
      end
    RUBY

    with_temp_file(complex_content) do |file_path|
      # Test that our parser can find all classes
      parser_result = RailsLens::Parsers::PrismParser.parse_file(file_path)

      assert_equal 1, parser_result.modules.size
      assert_equal 4, parser_result.classes.size

      # Test precise annotation placement for each class
      test_cases = [
        { class_name: 'BaseModel', expected_line: 4 },
        { class_name: 'UserModel', expected_line: 12 },
        { class_name: 'RegularModel', expected_line: 19 },
        { class_name: 'AnotherModel', expected_line: 27 }
      ]

      test_cases.each do |test_case|
        # Find the class in parser result
        found_class = parser_result.find_class(test_case[:class_name])

        assert_not_nil found_class, "Should find #{test_case[:class_name]}"
        assert_equal test_case[:expected_line], found_class.line_number,
                     "#{test_case[:class_name]} should be at line #{test_case[:expected_line]}"

        # Test annotation insertion
        annotation = "# ANNOTATION_FOR_#{test_case[:class_name].upcase}"
        success = RailsLens::FileInsertionHelper.insert_at_class_definition(
          file_path,
          test_case[:class_name],
          annotation
        )

        assert success, "Should successfully insert annotation for #{test_case[:class_name]}"

        # Verify the annotation was inserted
        result_content = File.read(file_path)

        assert_includes result_content, annotation,
                        "File should contain annotation for #{test_case[:class_name]}"

        # Verify the annotation is placed before the class definition
        lines = result_content.split("\n")

        # Find the annotation line
        annotation_line_index = lines.index { |line| line.include?(annotation) }

        assert_not_nil annotation_line_index, 'Should find annotation line'

        # Find the class definition line
        class_line_index = lines.index { |line| line.strip.start_with?("class #{test_case[:class_name]}") }

        assert_not_nil class_line_index, 'Should find class definition line'

        # Annotation should be right before the class definition (possibly with blank lines)
        assert_operator annotation_line_index, :<, class_line_index,
                        'Annotation should be before class definition'

        # For this test, all annotations go after frozen_string_literal
        # In a real Rails app, the annotation manager would handle this differently

        # Restore original content for next test
        File.write(file_path, complex_content)
      end
    end
  end

  def test_demonstrates_namespace_aware_class_finding
    complex_content = <<~RUBY
      # frozen_string_literal: true

      module Admin
        module Users
          class ProfileModel < ApplicationRecord
            def profile_method
              "profile method"
            end
          end
        end

        class UserModel < ApplicationRecord
          def user_method
            "user method"
          end
        end
      end

      class UserModel < ApplicationRecord
        def different_user_method
          "different user method"
        end
      end
    RUBY

    with_temp_file(complex_content) do |file_path|
      parser_result = RailsLens::Parsers::PrismParser.parse_file(file_path)

      # Should find nested modules
      assert_equal 2, parser_result.modules.size
      admin_module = parser_result.modules.find { |m| m.name == 'Admin' }
      users_module = parser_result.modules.find { |m| m.name == 'Users' }

      assert_not_nil admin_module
      assert_equal 3, admin_module.line_number
      assert_nil admin_module.namespace

      assert_not_nil users_module
      assert_equal 4, users_module.line_number
      assert_equal 'Admin', users_module.namespace

      # Should find classes with proper namespaces
      assert_equal 3, parser_result.classes.size

      profile_model = parser_result.classes.find { |c| c.name == 'ProfileModel' }

      assert_not_nil profile_model
      assert_equal 'Admin::Users', profile_model.namespace
      assert_equal 'Admin::Users::ProfileModel', profile_model.full_name

      admin_user_model = parser_result.classes.find { |c| c.name == 'UserModel' && c.namespace == 'Admin' }

      assert_not_nil admin_user_model
      assert_equal 'Admin::UserModel', admin_user_model.full_name

      root_user_model = parser_result.classes.find { |c| c.name == 'UserModel' && c.namespace.nil? }

      assert_not_nil root_user_model
      assert_equal 'UserModel', root_user_model.full_name

      # Test finding by different name patterns
      assert_not_nil parser_result.find_class('ProfileModel')
      assert_not_nil parser_result.find_class('Admin::Users::ProfileModel')
      assert_not_nil parser_result.find_class('UserModel') # Returns first match
      assert_not_nil parser_result.find_class('Admin::UserModel')
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
