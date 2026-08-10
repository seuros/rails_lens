# frozen_string_literal: true

require 'test_helper'

module RailsLens
  # Annotating twice must be a no-op the second time: unchanged models are
  # reported as skipped and their files are not rewritten.
  class AnnotationIdempotenceTest < ActiveSupport::TestCase
    def test_second_pass_rewrites_nothing
      models = [User, Post, Comment]

      Schema::AnnotationManager.annotate_all(models: models.map(&:name))

      files = models.map { |m| Rails.root.join('app', 'models', "#{m.name.underscore}.rb").to_s }
      before = files.index_with { |f| [File.read(f), File.mtime(f)] }

      results = Schema::AnnotationManager.annotate_all(models: models.map(&:name))

      models.each do |model|
        assert_not_includes results[:annotated], model.name,
                            "#{model.name} was rewritten although nothing changed"
      end
      files.each do |f|
        assert_equal before[f], [File.read(f), File.mtime(f)], "#{f} was touched on a no-op pass"
      end
    end

    def test_annotate_file_returns_false_when_unchanged
      manager = Schema::AnnotationManager.new(User)
      path = Rails.root.join('app/models/user.rb').to_s

      manager.annotate_file(path)

      assert_not manager.annotate_file(path)
    end
  end
end
