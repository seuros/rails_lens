# frozen_string_literal: true

module RailsLens
  module Configuration
    extend ActiveSupport::Concern

    included do
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
    end
  end
end
