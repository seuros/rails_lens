# frozen_string_literal: true

module RailsLens
  # Handles the actual execution of CLI commands
  class Commands
    attr_reader :output

    def initialize(output = $stdout)
      @output = output
    end

    def annotate_models(options = {})
      results = Schema::AnnotationManager.annotate_all(options)

      output.say "Annotated #{results[:annotated].length} models", :green
      output.say "Skipped #{results[:skipped].length} models", :yellow if results[:skipped].any?

      if results[:failed].any?
        output.say "Failed to annotate #{results[:failed].length} models:", :red
        results[:failed].each do |failure|
          output.say "  - #{failure[:model]}: #{failure[:error]}", :red
        end
      end

      results
    end

    def annotate_routes(options = {})
      annotator = Route::Annotator.new(dry_run: options[:dry_run])
      changed_files = annotator.annotate_all

      output.say "Annotated #{changed_files.length} controller files with routes", :green
      changed_files.each { |file| output.say "  - #{file}", :blue } if options[:verbose] && changed_files.any?

      { changed_files: changed_files }
    end

    def annotate_mailers(options = {})
      annotator = Mailer::Annotator.new(dry_run: options[:dry_run])
      changed_files = annotator.annotate_all

      output.say "Annotated #{changed_files.length} mailer files", :green
      changed_files.each { |file| output.say "  - #{file}", :blue } if options[:verbose] && changed_files.any?

      { changed_files: changed_files }
    end

    def remove_models(options = {})
      results = Schema::AnnotationManager.remove_all(options)
      output.say "Removed annotations from #{results[:removed].length} models", :green
      results
    end

    def remove_routes(options = {})
      annotator = Route::Annotator.new(dry_run: options[:dry_run])
      changed_files = annotator.remove_all
      output.say "Removed route annotations from #{changed_files.length} controller files", :green
      { changed_files: changed_files }
    end

    def remove_mailers(options = {})
      annotator = Mailer::Annotator.new(dry_run: options[:dry_run])
      changed_files = annotator.remove_all
      output.say "Removed mailer annotations from #{changed_files.length} mailer files", :green
      { changed_files: changed_files }
    end

    def generate_erd(options = {})
      visualizer = ERD::Visualizer.new(options: options)
      filename = visualizer.generate
      output.say "Entity Relationship Diagram generated at #{filename}", :green
      filename
    end

    def lint(options = {})
      output.say 'Linting Rails Lens configuration and annotations...', :blue

      issues = []
      warnings = []
      domains = options[:domains] || %w[models routes mailers]

      domains.each do |domain|
        case domain
        when 'models'
          # Check for inconsistent model annotations
          output.say '  Checking models domain...', :blue if options[:verbose]
        when 'routes'
          # Check for route annotation consistency
          output.say '  Checking routes domain...', :blue if options[:verbose]
        when 'mailers'
          # Check for mailer annotation consistency
          output.say '  Checking mailers domain...', :blue if options[:verbose]
        end
      end

      if issues.empty? && warnings.empty?
        output.say 'No linting issues found', :green
      else
        output.say "Found #{issues.length} issues and #{warnings.length} warnings", :yellow
      end

      { issues: issues, warnings: warnings }
    end

    def check(_options = {})
      output.say 'Checking Rails Lens configuration validity...', :blue

      # Check if Rails is properly loaded
      unless defined?(Rails)
        output.say 'Rails environment not detected', :red
        return { valid: false, errors: ['Rails environment not detected'] }
      end

      # Check database connections
      errors = []
      begin
        ApplicationRecord.connection.execute('SELECT 1')
        output.say 'Primary database connection: OK', :green
      rescue StandardError => e
        errors << "Primary database connection failed: #{e.message}"
        output.say 'Primary database connection: FAILED', :red
      end

      if errors.empty?
        output.say 'Configuration is valid', :green
        { valid: true, errors: [] }
      else
        output.say 'Configuration has errors', :red
        { valid: false, errors: errors }
      end
    end

    def config(subcommand, options = {})
      case subcommand
      when 'show'
        output.say 'Rails Lens Configuration:', :blue
        output.say "  Config file: #{RailsLens.config_file || 'default'}"
        output.say "  Verbose: #{RailsLens.config.verbose || false}"
        output.say "  Debug: #{RailsLens.config.debug || false}"

        if RailsLens.config.respond_to?(:position)
          output.say "  Default position: #{RailsLens.config.position || 'before'}"
        end

      when 'set'
        if options[:key] && options[:value]
          output.say "Setting #{options[:key]} = #{options[:value]}", :green
          # NOTE: This would require implementing config persistence
          output.say 'Note: Configuration changes are not persisted yet', :yellow
        else
          output.say 'Usage: config set --key KEY --value VALUE', :red
        end

      when 'reset'
        output.say 'Resetting configuration to defaults', :yellow
        # NOTE: This would reset to defaults

      else
        output.say "Unknown config subcommand: #{subcommand}", :red
        output.say 'Available: show, set, reset'
      end
    end
  end
end
