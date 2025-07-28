# frozen_string_literal: true

require 'test_helper'

class RailsLensTest < ActiveSupport::TestCase
  def test_that_it_has_a_version_number
    assert_not_nil ::RailsLens::VERSION
  end

  def test_configuration_using_activesupport_configurable
    assert_respond_to RailsLens, :config
    assert_respond_to RailsLens, :configure
  end

  def test_default_annotations_configuration
    assert_equal :before, RailsLens.config.annotations[:position]
    assert_equal :rdoc, RailsLens.config.annotations[:format]
  end

  def test_default_erd_configuration
    assert_equal 'doc/erd', RailsLens.config.erd[:output_dir]
    assert_equal 'TB', RailsLens.config.erd[:orientation]
  end
end
