# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Extensions
    class ClosureTreeExtTest < ActiveSupport::TestCase
      def setup
        # Use the real Family model which has closure_tree configured
        @model = Family
        @connection = @model.connection
      end

      # Basic functionality tests

      def test_gem_name
        assert_equal 'closure_tree', ClosureTreeExt.gem_name
      end

      def test_detect_when_closure_tree_loaded
        # Mock gem being available
        ClosureTreeExt.stub(:gem_available?, true) do
          assert_predicate ClosureTreeExt, :detect?
        end
      end

      def test_detect_when_closure_tree_not_loaded
        # Mock gem not being available
        ClosureTreeExt.stub(:gem_available?, false) do
          assert_not_predicate ClosureTreeExt, :detect?
        end
      end

      def test_annotate_without_closure_tree
        # Test with a regular model that doesn't have closure_tree
        extension = ClosureTreeExt.new(User)

        assert_nil extension.annotate
      end

      def test_annotate_with_basic_closure_tree
        extension = ClosureTreeExt.new(@model)
        result = extension.annotate

        assert_match(/== Hierarchy \(ClosureTree\)/, result)
        assert_match(/Parent Column: parent_id/, result)
        assert_match(/Hierarchy Table: family_hierarchies/, result)
        assert_match(/Order Column: name/, result)
      end

      def test_notes_without_closure_tree
        extension = ClosureTreeExt.new(User)

        assert_empty extension.notes
      end

      def test_notes_with_closure_tree
        extension = ClosureTreeExt.new(@model)
        notes = extension.notes

        assert_kind_of Array, notes
        # Family model should have various closure tree related notes
        assert(notes.any? { |note| note.include?('parent_id') })
      end

      def test_model_uses_closure_tree
        extension = ClosureTreeExt.new(@model)

        assert extension.send(:model_uses_closure_tree?)
      end

      def test_model_does_not_use_closure_tree
        extension = ClosureTreeExt.new(User)

        assert_not extension.send(:model_uses_closure_tree?)
      end

      def test_parent_column_name
        extension = ClosureTreeExt.new(@model)

        assert_equal 'parent_id', extension.send(:parent_column_name)
      end

      def test_hierarchy_table_name
        extension = ClosureTreeExt.new(@model)

        assert_equal 'family_hierarchies', extension.send(:hierarchy_table_name)
      end

      def test_handles_ct_config_errors_gracefully
        extension = ClosureTreeExt.new(@model)
        result = extension.annotate

        # Should work with normal ClosureTree configuration
        assert_match(/Parent Column: parent_id/, result)
        assert_match(/Hierarchy Table: family_hierarchies/, result)
      end

      def test_invalid_closure_tree_configuration
        extension = ClosureTreeExt.new(@model)

        # Should handle gracefully with normal ClosureTree
        result = extension.annotate
        notes = extension.notes

        assert_kind_of Array, notes
        assert_not_nil result
      end
    end
  end
end
