# frozen_string_literal: true

require 'thor'
require_relative 'commands'
require_relative 'cli_error_handler'

module RailsLens
  class CLI < Thor
    include CLIErrorHandler

    # Thor configuration: exit with proper status codes on failure (modern behavior)
    def self.exit_on_failure?
      true
    end

    class_option :config, type: :string, default: '.rails-lens.yml', desc: 'Configuration file path'
    class_option :dry_run, type: :boolean, desc: 'Show what would be done without making changes'
    class_option :verbose, type: :boolean, desc: 'Verbose output'
    class_option :debug, type: :boolean, desc: 'Debug output with full backtraces'

    desc 'annotate', 'Annotate Rails models with schema information'
    option :models, type: :array, desc: 'Specific models to annotate'
    option :include_abstract, type: :boolean, desc: 'Include abstract classes'
    option :position, type: :string, enum: %w[before after top bottom], desc: 'Annotation position'
    option :routes, type: :boolean, desc: 'Annotate controller routes'
    option :mailers, type: :boolean, desc: 'Annotate mailer methods'
    option :all, type: :boolean, desc: 'Annotate models, routes, and mailers'
    def annotate
      with_error_handling do
        setup_environment

        results = {}
        commands = Commands.new(self)

        # Annotate models (default behavior or when --all is specified)
        results[:models] = commands.annotate_models(options) if should_annotate_models?

        # Annotate routes
        results[:routes] = commands.annotate_routes(options) if should_annotate_routes?

        # Annotate mailers
        results[:mailers] = commands.annotate_mailers(options) if should_annotate_mailers?

        results
      end
    end

    desc 'remove', 'Remove annotations from Rails files'
    option :routes, type: :boolean, desc: 'Remove controller route annotations'
    option :mailers, type: :boolean, desc: 'Remove mailer annotations'
    option :all, type: :boolean, desc: 'Remove all annotations'
    def remove
      with_error_handling do
        setup_environment

        results = {}
        commands = Commands.new(self)

        # Remove model annotations (default behavior or when --all is specified)
        results[:models] = commands.remove_models(options) if should_remove_models?

        # Remove route annotations
        results[:routes] = commands.remove_routes(options) if should_remove_routes?

        # Remove mailer annotations
        results[:mailers] = commands.remove_mailers(options) if should_remove_mailers?

        results
      end
    end

    desc 'erd', 'Generate Entity Relationship Diagram (Mermaid format)'
    option :output, type: :string, desc: 'Output directory'
    option :verbose, type: :boolean, desc: 'Verbose output'
    option :group_by_database, type: :boolean, desc: 'Group models by database connection instead of domain'
    def erd
      with_error_handling do
        setup_environment

        # Transform CLI options to visualizer options
        visualizer_options = options.dup
        visualizer_options[:output_dir] = options[:output] if options[:output]

        commands = Commands.new(self)
        commands.generate_erd(visualizer_options)
      end
    end

    desc 'version', 'Show Rails Lens version'
    def version
      say "Rails Lens #{RailsLens::VERSION}"
    end

    desc 'lint', 'Lint Rails Lens configuration and model annotations'
    option :domains, type: :array, desc: 'Specific domains to lint (models, routes, mailers)'
    def lint
      with_error_handling do
        setup_environment

        commands = Commands.new(self)
        commands.lint(options)
      end
    end

    desc 'check', 'Check Rails Lens configuration validity'
    def check
      with_error_handling do
        setup_environment

        commands = Commands.new(self)
        commands.check(options)
      end
    end

    desc 'config SUBCOMMAND', 'Manage Rails Lens configuration'
    option :key, type: :string, desc: 'Configuration key'
    option :value, type: :string, desc: 'Configuration value'
    def config(subcommand = 'show')
      with_error_handling do
        setup_environment

        commands = Commands.new(self)
        commands.config(subcommand, options)
      end
    end

    private

    def setup_environment
      RakeBootstrapper.call
      load_configuration(options[:config])
      configure_error_reporting
    end

    def load_configuration(config_file)
      if File.exist?(config_file)
        RailsLens.load_config_file(config_file)
        say "Loaded configuration from #{config_file}", :green if options[:verbose]
      elsif config_file != '.rails-lens.yml'
        raise ConfigurationError, "Configuration file not found: #{config_file}"
      elsif options[:verbose]
        say "Using default configuration (#{config_file} not found)", :yellow
      end
    end

    def configure_error_reporting
      RailsLens.config.verbose = options[:verbose]
      RailsLens.config.debug = options[:debug]
    end

    # Helper methods to determine what to annotate/remove
    def should_annotate_models?
      (!options[:routes] && !options[:mailers]) || options[:all]
    end

    def should_annotate_routes?
      options[:routes] || options[:all]
    end

    def should_annotate_mailers?
      options[:mailers] || options[:all]
    end

    def should_remove_models?
      (!options[:routes] && !options[:mailers]) || options[:all]
    end

    def should_remove_routes?
      options[:routes] || options[:all]
    end

    def should_remove_mailers?
      options[:mailers] || options[:all]
    end
  end
end
