# frozen_string_literal: true

require 'zeitwerk'
require 'rails'
require 'active_record'
require 'active_support'
require 'thor'
require 'ostruct'

require_relative 'rails_lens/version'
require_relative 'rails_lens/railtie' if defined?(Rails::Railtie)

loader = Zeitwerk::Loader.for_gem
loader.ignore(File.join(__dir__, 'rails_lens/errors.rb'))
loader.ignore(File.join(__dir__, 'rails_lens/analyzers/error_handling.rb'))
loader.ignore(File.join(__dir__, 'rails_lens/cli.rb'))
loader.ignore(File.join(__dir__, 'rails_lens/commands.rb'))
loader.ignore(File.join(__dir__, 'rails_lens/cli_error_handler.rb'))
loader.inflector.inflect(
  'cli' => 'CLI',
  'erd' => 'ERD',
  'ast_file_modifier' => 'ASTFileModifier'
)
loader.setup

require_relative 'rails_lens/errors'
require_relative 'rails_lens/cli'
require_relative 'rails_lens/configuration'

module RailsLens
  extend Configuration

  class << self
    def logger
      @logger ||= config.logger || default_logger
    end

    def logger=(new_logger)
      @logger = new_logger
      config.logger = new_logger
    end

    def default_logger
      if defined?(Rails.logger) && Rails.logger
        Rails.logger
      else
        require 'logger'
        Logger.new($stdout)
      end
    end

    def load_config_file(path = '.rails-lens.yml')
      return unless File.exist?(path)

      yaml = YAML.load_file(path)

      yaml.each do |section, settings|
        next unless config.respond_to?("#{section}=")
        next unless settings.is_a?(Hash)

        current_value = config.send(section)
        if current_value.is_a?(Hash)
          config.send("#{section}=", current_value.merge(settings.symbolize_keys))
        else
          config.send("#{section}=", settings.symbolize_keys)
        end
      end
    end

    # Get tables to exclude
    def excluded_tables
      custom_excludes = config.schema[:exclude_tables]
      if custom_excludes.nil?
        # Use ActiveRecord's default ignore tables
        ActiveRecord::SchemaDumper.ignore_tables.to_a
      else
        Array(custom_excludes)
      end
    end

    # Schema annotation methods
    def annotate_models(options = {})
      Schema::AnnotationManager.annotate_all(options)
    end

    def remove_annotations(options = {})
      Schema::AnnotationManager.remove_all(options)
    end
  end
end
