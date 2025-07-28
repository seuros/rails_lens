# frozen_string_literal: true

require 'test_helper'
require 'fileutils'

class DummyAppTest < ActiveSupport::TestCase
  def setup
    @dummy_path = File.expand_path('../dummy', __dir__)
    @original_dir = Dir.pwd
    Dir.chdir(@dummy_path)
  end

  def teardown
    Dir.chdir(@original_dir)
  end

  def test_rails_lens_is_loaded
    assert defined?(RailsLens)
    assert defined?(RailsLens::ERD)
    assert defined?(RailsLens::Schema)
  end
end
