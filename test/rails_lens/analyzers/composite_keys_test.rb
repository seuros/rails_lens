# frozen_string_literal: true

require 'test_helper'

module RailsLens
  module Analyzers
    class CompositeKeysTest < ActiveSupport::TestCase
      def test_single_primary_key_models_return_nil
        [User, Post, Vehicle, Family].each do |model|
          assert_nil CompositeKeys.new(model).analyze, "#{model.name} should not have composite key info"
        end
      end

      def test_composite_primary_key_emits_toml_section
        result = CompositeKeys.new(OrderLineItem).analyze

        assert_equal "[composite_pk]\nkeys = [\"order_id\", \"line_number\"]", result
      end

      def test_detection_uses_native_rails_primary_key
        assert_equal %w[order_id line_number], OrderLineItem.primary_key
        assert_equal 'id', User.primary_key
      end

      def test_nil_primary_key_returns_nil
        User.stub(:primary_key, nil) do
          assert_nil CompositeKeys.new(User).analyze
        end
      end
    end
  end
end
