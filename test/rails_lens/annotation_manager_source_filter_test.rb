# frozen_string_literal: true

require 'test_helper'
require 'rails_lens/schema/annotation_manager'

class AnnotationManagerSourceFilterTest < ActiveSupport::TestCase
  # A source that ignores options[:models], like external graph-model sources
  # (e.g. ActiveCypher) that return their full model list regardless of filter.
  class UnfilteredSource < RailsLens::ModelSource
    class << self
      attr_accessor :model_list, :annotated

      def models(_options = {})
        model_list
      end

      def annotate_model(model, _options = {})
        self.annotated ||= []
        annotated << model.name
        { status: :annotated, model: model.name }
      end

      def source_name
        'Unfiltered'
      end
    end
  end

  class ExplodingSource < RailsLens::ModelSource
    class << self
      def models(_options = {})
        raise 'boom'
      end

      def source_name
        'Exploding'
      end
    end
  end

  def fake_model(name, table_name = nil)
    Class.new do
      define_singleton_method(:name) { name }
      define_singleton_method(:table_name) { table_name } if table_name
    end
  end

  setup do
    UnfilteredSource.annotated = []
    UnfilteredSource.model_list = [
      fake_model('FakeUser', 'fake_users'),
      fake_model('FakePost', 'fake_posts'),
      fake_model('FakeNode')
    ]
  end

  def test_filter_models_by_names_returns_all_without_filter
    models = UnfilteredSource.model_list

    assert_equal models, RailsLens::Schema::AnnotationManager.filter_models_by_names(models, nil)
    assert_equal models, RailsLens::Schema::AnnotationManager.filter_models_by_names(models, [])
  end

  def test_filter_models_by_names_matches_class_name
    models = UnfilteredSource.model_list
    filtered = RailsLens::Schema::AnnotationManager.filter_models_by_names(models, ['FakeUser'])

    assert_equal %w[FakeUser], filtered.map(&:name)
  end

  def test_filter_models_by_names_matches_table_name
    models = UnfilteredSource.model_list
    filtered = RailsLens::Schema::AnnotationManager.filter_models_by_names(models, ['fake_posts'])

    assert_equal %w[FakePost], filtered.map(&:name)
  end

  def test_filter_models_by_names_handles_models_without_table_name
    models = UnfilteredSource.model_list
    filtered = RailsLens::Schema::AnnotationManager.filter_models_by_names(models, ['FakeNode'])

    assert_equal %w[FakeNode], filtered.map(&:name)
  end

  def test_annotate_source_enforces_models_filter_on_sources_that_ignore_it
    results = RailsLens::Schema::AnnotationManager.annotate_source(
      UnfilteredSource, { models: ['FakeUser'] }
    )

    assert_equal %w[FakeUser], results[:annotated]
    assert_equal %w[FakeUser], UnfilteredSource.annotated
  end

  def test_annotate_source_with_unmatched_filter_annotates_nothing
    results = RailsLens::Schema::AnnotationManager.annotate_source(
      UnfilteredSource, { models: ['models'] }
    )

    assert_empty results[:annotated]
    assert_empty results[:skipped]
    assert_empty results[:failed]
    assert_empty UnfilteredSource.annotated
  end

  def test_annotate_source_records_source_errors_as_failures
    results = RailsLens::Schema::AnnotationManager.annotate_source(ExplodingSource, {})

    assert_equal 1, results[:failed].length
    assert_equal 'Exploding (source)', results[:failed].first[:model]
    assert_equal 'boom', results[:failed].first[:error]
  end
end
