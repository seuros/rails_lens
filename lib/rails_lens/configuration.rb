# frozen_string_literal: true

module RailsLens
  class Config
    attr_accessor :verbose, :debug, :raise_on_error, :logger,
                  :annotations, :erd, :schema, :extensions, :routes, :mailers

    def initialize
      @verbose = false
      @debug = false
      @raise_on_error = false
      @logger = nil

      @annotations = {
        position: :before,
        format: :rdoc
      }

      @erd = {
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

      @schema = {
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

      @extensions = {
        enabled: true,
        autoload: true,
        interface_version: '1.0',
        ignore: [],
        custom_paths: [],
        error_reporting: :warn,    # :silent, :warn, :verbose
        fail_safe_mode: true,      # Continue processing if extensions fail
        track_health: false        # Track extension success/failure rates
      }

      @routes = {
        enabled: true,
        include_defaults: true,
        include_constraints: true,
        pattern: '**/*_controller.rb',
        exclusion_pattern: 'vendor/**/*_controller.rb'
      }

      @mailers = {
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

  module Configuration
    def config
      @config ||= Config.new
    end

    def configure
      yield config if block_given?
    end
  end
end
