# frozen_string_literal: true

require 'test_helper'

module RailsLens
  class TomlFormatTest < ActiveSupport::TestCase
    def test_quoted_array_wraps_and_quotes_values
      assert_equal '["a", "b"]', TomlFormat.quoted_array(%w[a b])
    end

    def test_quoted_array_with_single_value
      assert_equal '["only"]', TomlFormat.quoted_array(['only'])
    end

    def test_quoted_array_with_empty_collection
      assert_equal '[]', TomlFormat.quoted_array([])
    end

    def test_quoted_array_stringifies_non_string_values
      assert_equal '["1", "2"]', TomlFormat.quoted_array([1, 2])
    end

    def test_quoted_array_preserves_order
      assert_equal '["z", "a", "m"]', TomlFormat.quoted_array(%w[z a m])
    end
  end
end
