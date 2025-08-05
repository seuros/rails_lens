# frozen_string_literal: true

require 'zeitwerk'
require 'rails'
require 'active_record'
require 'active_support'
require 'active_support/configurable'
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

module RailsLens
  include ActiveSupport::Configurable

  # Add configuration for error handling
  config_accessor :verbose, default: false
  config_accessor :debug, default: false
  config_accessor :raise_on_error, default: false

  # Logger configuration
  config_accessor :logger

  # Configuration using ActiveSupport::Configurable
  config_accessor :annotations do
    {
      position: :before,
      format: :rdoc
    }
  end

  config_accessor :erd do
    {
      output_dir: 'doc/erd',
      orientation: 'TB',
      theme: true,
      default_colors: %w[
        lightblue
        lightcoral
        lightgreen
        lightyellow
        plum
        lightcyan
        lightgray
      ]
    }
  end

  config_accessor :schema do
    {
      adapter: :auto,
      include_notes: true,
      exclude_tables: nil, # Will use ActiveRecord::SchemaDumper.ignore_tables if nil
      format_options: {
        show_defaults: true,
        show_comments: true,
        show_foreign_keys: true,
        show_indexes: true,
        show_check_constraints: true
      }
    }
  end

  config_accessor :extensions do
    {
      enabled: true,
      autoload: true,
      interface_version: '1.0',
      ignore: [],
      custom_paths: [],
      error_reporting: :warn,    # :silent, :warn, :verbose
      fail_safe_mode: true,      # Continue processing if extensions fail
      track_health: false        # Track extension success/failure rates
    }
  end

  config_accessor :routes do
    {
      enabled: true,
      include_defaults: true,
      include_constraints: true,
      pattern: '**/*_controller.rb',
      exclusion_pattern: 'vendor/**/*_controller.rb'
    }
  end

  config_accessor :mailers do
    {
      enabled: true,
      include_templates: true,
      include_delivery_methods: true,
      include_variables: true,
      include_locales: true,
      include_defaults: true,
      pattern: '**/*_mailer.rb',
      exclusion_pattern: 'vendor/**/*_mailer.rb'
    }
  end

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
