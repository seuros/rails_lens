# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rails-lens.gemspec
gemspec

gem 'irb'
gem 'rake', '~> 13.0'

gem 'minitest', '~> 5.17'
gem 'minitest-reporters', '~> 1.6'

# Support testing against different Rails versions
if ENV['RAILS_VERSION']
  rails_version = ENV['RAILS_VERSION']
  gem 'actionmailer', "~> #{rails_version}.0"
  gem 'activerecord', "~> #{rails_version}.0"
  gem 'railties', "~> #{rails_version}.0"
else
  gem 'actionmailer', '>= 7.2.0'
end

# PostGIS adapter only supports Rails 8+
gem 'activerecord-postgis' if !ENV['RAILS_VERSION'] || ENV['RAILS_VERSION'].to_i >= 8
gem 'closure_tree'
gem 'dotenv', '~> 3.0'
gem 'rubocop', '~> 1.66'
gem 'rubocop-minitest', '~> 0.36'
gem 'rubocop-rails', '~> 2.26'
gem 'rubocop-rake', '~> 0.6'
gem 'simplecov', require: false
gem 'with_advisory_lock'

gem 'mermaid', '>= 0.0.6'
