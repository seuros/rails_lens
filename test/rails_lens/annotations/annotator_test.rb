# frozen_string_literal: true

require 'test_helper'
require 'tempfile'
require 'rails_lens/schema/annotation'

module RailsLens
  module Annotations
    class AnnotatorTest < ActiveSupport::TestCase
      def setup
        @annotation = RailsLens::Schema::Annotation.new
      end

      def test_annotation_initializes
        assert_instance_of RailsLens::Schema::Annotation, @annotation
        assert_equal 'rails-lens:schema', RailsLens::Schema::Annotation::MARKER_FORMAT
      end

      def test_start_and_end_markers
        assert_equal '# <rails-lens:schema:begin>', @annotation.start_marker
        assert_equal '# <rails-lens:schema:end>', @annotation.end_marker
      end

      def test_add_line
        @annotation.add_line('TABLE: users')

        assert_includes @annotation.to_s, '# TABLE: users'
      end

      def test_add_lines
        @annotation.add_lines(['TABLE: users', 'DATABASE_DIALECT: PostgreSQL'])
        result = @annotation.to_s

        assert_includes result, '# TABLE: users'
        assert_includes result, '# DATABASE_DIALECT: PostgreSQL'
      end

      def test_to_s_with_content
        @annotation.add_line('TABLE: users')
        @annotation.add_line('DATABASE_DIALECT: PostgreSQL')

        result = @annotation.to_s

        assert_includes result, '# <rails-lens:schema:begin>'
        assert_includes result, '# TABLE: users'
        assert_includes result, '# DATABASE_DIALECT: PostgreSQL'
        assert_includes result, '# <rails-lens:schema:end>'
      end

      def test_extract_annotation
        content = <<~RUBY
          # frozen_string_literal: true
          # <rails-lens:schema:begin>
          # TABLE: users
          # DATABASE_DIALECT: PostgreSQL
          # <rails-lens:schema:end>

          class User < ApplicationRecord
          end
        RUBY

        extracted = RailsLens::Schema::Annotation.extract(content)

        assert extracted
        assert_includes extracted[:content], 'TABLE: users'
        assert_includes extracted[:content], 'DATABASE_DIALECT: PostgreSQL'
      end

      def test_remove_annotations
        content = <<~RUBY
          # frozen_string_literal: true
          # <rails-lens:schema:begin>
          # TABLE: users
          # DATABASE_DIALECT: PostgreSQL
          # <rails-lens:schema:end>

          class User < ApplicationRecord
          end
        RUBY

        cleaned = RailsLens::Schema::Annotation.remove(content)

        assert_not_includes cleaned, 'rails-lens:schema:begin'
        assert_not_includes cleaned, 'rails-lens:schema:end'
        assert_not_includes cleaned, 'TABLE: users'
        assert_includes cleaned, 'class User'
      end
    end
  end
end
