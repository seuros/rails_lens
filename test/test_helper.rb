# frozen_string_literal: true

# Disable SimpleCov in CI to avoid rake abort issues
unless ENV['CI']
  require 'simplecov'

  # Start SimpleCov before loading the Rails app
  SimpleCov.start 'rails' do
    add_filter '/test/'
    add_filter '/test/integration/dummy/'
    add_filter '/vendor/'
    add_filter '/config/'

    add_group 'Analyzers', 'lib/rails_lens/analyzers'
    add_group 'Schema', 'lib/rails_lens/schema'
    add_group 'Extensions', 'lib/rails_lens/extensions'
    add_group 'CLI', 'lib/rails_lens/cli'
    add_group 'Core', 'lib/rails_lens.rb'

    minimum_coverage 0
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('.', __dir__)
require 'rails_lens'

# Load Rails environment to get database models
ENV['RAILS_ENV'] ||= 'test'
require_relative 'dummy/config/environment'
require 'rails/test_help'
require 'minitest/mock'
require 'minitest/reporters'

# Configure minitest-reporters to show test timing
Minitest::Reporters.use! [
  Minitest::Reporters::DefaultReporter.new(color: true, slow_count: 5),
  Minitest::Reporters::SpecReporter.new
]

# Load test support files
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

ApplicationRecord.establish_connection(:primary)
VehicleRecord.establish_connection(:vehicles)
PrehistoricRecord.establish_connection(:prehistoric)
