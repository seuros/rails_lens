# frozen_string_literal: true

require_relative 'lib/rails_lens/version'

Gem::Specification.new do |spec|
  spec.name = 'rails_lens'
  spec.version = RailsLens::VERSION
  spec.authors = ['Abdelkader Boudih']
  spec.email = ['terminale@gmail.com']

  spec.summary = 'Comprehensive Rails application visualization and annotation'
  spec.description = 'Rails Lens provides unified visualization and annotation for Rails 7.2+ applications, ' \
                     'integrating ERD generation and model annotations.'
  spec.homepage = 'https://github.com/seuros/rails_lens'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/seuros/rails_lens'
  spec.metadata['changelog_uri'] = 'https://github.com/seuros/rails_lens/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob('lib/**/*') + Dir.glob('exe/*') + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.bindir = 'exe'
  spec.executables = %w[rails_lens]
  spec.require_paths = ['lib']

  # Rails dependencies
  spec.add_dependency 'activerecord', '>= 7.2.0'
  spec.add_dependency 'railties', '>= 7.2.0'

  # CLI and utilities
  spec.add_dependency 'ostruct'
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'zeitwerk', '~> 2.7'

  # Development dependencies
  spec.add_development_dependency 'actionmailer', '>= 7.2.0'
  spec.add_development_dependency 'dotenv', '~> 3.0'
  spec.add_development_dependency 'mysql2', '~> 0.5'
  spec.add_development_dependency 'pg', '~> 1.5'
  spec.add_development_dependency 'sqlite3', '~> 2.0'
end
