# frozen_string_literal: true

require 'test_helper'

class EndToEndAnnotationTest < ActiveSupport::TestCase
  def test_demonstrates_complete_annotation_workflow_with_multiple_classes
    # Create a realistic Rails model file with multiple classes
    model_content = <<~RUBY
      # frozen_string_literal: true

      # This is a comment about the module
      module Blog
        # Base class for blog models
        class BaseModel < ApplicationRecord
          self.abstract_class = true

          scope :active, -> { where(active: true) }

          def blog_method
            "blog method"
          end
        end

        # Post model with validation
        class Post < BaseModel
          belongs_to :author, class_name: 'User'
          has_many :comments

          validates :title, presence: true
          validates :content, presence: true

          def published?
            published_at.present?
          end
        end

        # Comment model
        class Comment < BaseModel
          belongs_to :post
          belongs_to :author, class_name: 'User'

          validates :body, presence: true

          def approved?
            approved_at.present?
          end
        end
      end

      # Regular user model outside the module
      class User < ApplicationRecord
        has_many :posts, foreign_key: :author_id, class_name: 'Blog::Post'
        has_many :comments, foreign_key: :author_id, class_name: 'Blog::Comment'

        validates :email, presence: true, uniqueness: true
        validates :name, presence: true

        def full_name
          "full name"
        end
      end
    RUBY

    with_temp_file(model_content) do |file_path|
      # Step 1: Parse the file and verify structure
      parser_result = RailsLens::Parsers::PrismParser.parse_file(file_path)

      assert_equal 1, parser_result.modules.size
      assert_equal 4, parser_result.classes.size

      # Verify module structure
      blog_module = parser_result.modules.first

      assert_equal 'Blog', blog_module.name
      assert_equal 4, blog_module.line_number

      # Verify class structure
      classes = parser_result.classes
      base_model = classes.find { |c| c.name == 'BaseModel' }
      post_model = classes.find { |c| c.name == 'Post' }
      comment_model = classes.find { |c| c.name == 'Comment' }
      user_model = classes.find { |c| c.name == 'User' }

      assert_not_nil base_model
      assert_equal 'Blog', base_model.namespace
      assert_equal 6, base_model.line_number

      assert_not_nil post_model
      assert_equal 'Blog', post_model.namespace
      assert_equal 17, post_model.line_number

      assert_not_nil comment_model
      assert_equal 'Blog', comment_model.namespace
      assert_equal 30, comment_model.line_number

      assert_not_nil user_model
      assert_nil user_model.namespace
      assert_equal 43, user_model.line_number

      # Step 2: Test annotation insertion for each class
      test_annotations = [
        { class_name: 'BaseModel', annotation: '# Base model annotation' },
        { class_name: 'Post', annotation: '# Post model annotation' },
        { class_name: 'Comment', annotation: '# Comment model annotation' },
        { class_name: 'User', annotation: '# User model annotation' }
      ]

      test_annotations.each do |test_case|
        # Insert annotation
        success = RailsLens::FileInsertionHelper.insert_at_class_definition(
          file_path,
          test_case[:class_name],
          test_case[:annotation]
        )

        assert success, "Should insert annotation for #{test_case[:class_name]}"

        # Verify annotation was inserted
        content = File.read(file_path)

        assert_includes content, test_case[:annotation]

        # Verify structure is maintained
        lines = content.split("\n")

        assert_equal '# frozen_string_literal: true', lines[0]
        assert_equal '', lines[1]

        # The annotation should appear at the beginning after frozen_string_literal
        assert_includes lines[2], '# ', 'Line 2 should contain an annotation'

        # Restore original content for next test
        File.write(file_path, model_content)
      end

      # Step 3: Test finding classes by different naming patterns
      assert_not_nil parser_result.find_class('BaseModel')
      assert_not_nil parser_result.find_class('Blog::BaseModel')
      assert_not_nil parser_result.find_class('Post')
      assert_not_nil parser_result.find_class('Blog::Post')
      assert_not_nil parser_result.find_class('Comment')
      assert_not_nil parser_result.find_class('Blog::Comment')
      assert_not_nil parser_result.find_class('User')

      # Step 4: Test that non-existent classes return nil
      assert_nil parser_result.find_class('NonExistentModel')
      assert_nil parser_result.find_class('Blog::NonExistentModel')

      # Step 5: Test complex scenarios
      # What happens when we have multiple classes with similar names?
      complex_content = <<~RUBY
        # frozen_string_literal: true

        class User < ApplicationRecord
          def method1; end
        end

        module Admin
          class User < ApplicationRecord
            def method2; end
          end
        end

        module Blog
          class User < ApplicationRecord
            def method3; end
          end
        end
      RUBY

      File.write(file_path, complex_content)

      complex_result = RailsLens::Parsers::PrismParser.parse_file(file_path)

      assert_equal 2, complex_result.modules.size
      assert_equal 3, complex_result.classes.size

      # Should find the first User class (root namespace)
      found_user = complex_result.find_class('User')

      assert_not_nil found_user
      assert_nil found_user.namespace
      assert_equal 3, found_user.line_number

      # Should find specific namespaced users
      admin_user = complex_result.find_class('Admin::User')

      assert_not_nil admin_user
      assert_equal 'Admin', admin_user.namespace

      blog_user = complex_result.find_class('Blog::User')

      assert_not_nil blog_user
      assert_equal 'Blog', blog_user.namespace
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
