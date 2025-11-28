# frozen_string_literal: true

require_relative 'boot'

# Load environment variables
require 'dotenv'
Dotenv.load

require 'rails'
require 'active_support/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'rails/test_unit/railtie'

# Include ActionMailer if available (optional dependency)
begin
  require 'action_mailer/railtie'
rescue LoadError
  # ActionMailer not available, skip it
end

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)

# Require rails_lens from the parent directory
require_relative '../../../lib/rails_lens'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # Only load the frameworks we need
    config.api_only = true

    # Skip some Rails features we don't need
    config.generators.system_tests = nil

    # Multi-database configuration
    config.active_record.database_selector = { delay: 2 }
    config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
    config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

    # Disable schema dump to preserve manually maintained schema.rb
    # (includes audit.audit_logs table and other non-standard structures)
    config.active_record.dump_schema_after_migration = false
  end
end
