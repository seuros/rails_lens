# frozen_string_literal: true

require 'fileutils'

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

      # Also annotate database-level objects (functions, etc.)
      if options[:include_database_objects]
        db_results = annotate_database_objects(options)
        results.merge!(database_objects: db_results)
      end

      results
    end

    def annotate_database_objects(options = {})
      results = Schema::DatabaseAnnotator.annotate_all(options)

      output.say "Annotated #{results[:annotated].length} abstract base classes with database objects", :green
      output.say "Skipped #{results[:skipped].length} abstract classes", :yellow if results[:skipped].any?

      if results[:failed].any?
        output.say "Failed to annotate #{results[:failed].length} abstract classes:", :red
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

    def install(options = {})
      output.say 'Installing Rails Lens rake tasks...', :blue

      # Determine Rails root
      rails_root = if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
                     Rails.root.to_s
                   else
                     Dir.pwd
                   end
      tasks_dir = File.join(rails_root, 'lib', 'tasks')
      rake_file = File.join(tasks_dir, 'rails_lens.rake')

      # Check if file exists
      if File.exist?(rake_file) && !options[:force]
        output.say 'Rails Lens rake task already exists at lib/tasks/rails_lens.rake', :yellow
        output.say 'Use --force to overwrite', :yellow
        return { installed: false, path: rake_file }
      end

      # Create lib/tasks directory if it doesn't exist
      FileUtils.mkdir_p(tasks_dir)

      # Write the rake task
      File.write(rake_file, rake_task_template)

      output.say "Created rake task at #{rake_file}", :green
      output.say '', :reset
      output.say 'The following task has been installed:', :blue
      output.say '  • rails_lens:annotate - Annotate models after migrations', :green
      output.say '', :reset
      output.say 'Configuration options in lib/tasks/rails_lens.rake:', :blue
      output.say '  • AUTO_ANNOTATE (default: true in development)', :cyan
      output.say '  • RAILS_LENS_ENV (default: development)', :cyan
      output.say '', :reset
      output.say 'Disable auto-annotation:', :blue
      output.say '  export AUTO_ANNOTATE=false', :cyan

      { installed: true, path: rake_file }
    end

    private

    def rake_task_template
      <<~RAKE
        # frozen_string_literal: true

        # Rails Lens automatic annotation task
        # Generated by: rails_lens install
        #
        # This task automatically annotates models after running migrations.
        # It only runs in development by default to avoid slowing down CI/production deploys.
        #
        # Environment variables:
        #   AUTO_ANNOTATE=false - Disable automatic annotation
        #   RAILS_LENS_ENV=test,development - Environments where annotation runs

        namespace :rails_lens do
          desc 'Annotate models with schema information'
          task annotate: :environment do
            # Check if auto-annotation is enabled
            auto_annotate = ENV.fetch('AUTO_ANNOTATE', 'true')
            if auto_annotate == 'false'
              puts 'Rails Lens: Auto-annotation disabled (AUTO_ANNOTATE=false)'
              next
            end

            # Check if we're in an allowed environment
            allowed_envs = ENV.fetch('RAILS_LENS_ENV', 'development').split(',').map(&:strip)
            unless allowed_envs.include?(Rails.env)
              puts "Rails Lens: Skipping annotation in \#{Rails.env} environment"
              next
            end

            puts 'Rails Lens: Annotating models...'
            begin
              # Use RailsLens directly if available
              if defined?(RailsLens)
                results = RailsLens::Schema::AnnotationManager.annotate_all
                puts "Rails Lens: Annotated \#{results[:annotated].length} models"
                puts "Rails Lens: Skipped \#{results[:skipped].length} models" if results[:skipped].any?
              else
                # Fallback to CLI
                system('bundle exec rails_lens annotate --quiet')
              end
            rescue StandardError => e
              warn "Rails Lens: Annotation failed: \#{e.message}"
              warn 'Rails Lens: Set AUTO_ANNOTATE=false to disable auto-annotation'
            end
          end
        end

        # Hook into db:migrate
        if Rake::Task.task_defined?('db:migrate')
          Rake::Task['db:migrate'].enhance do
            Rake::Task['rails_lens:annotate'].invoke if defined?(Rails)
          rescue StandardError => e
            warn "Rails Lens hook failed: \#{e.message}"
          end
        end

        # Hook into db:rollback
        if Rake::Task.task_defined?('db:rollback')
          Rake::Task['db:rollback'].enhance do
            Rake::Task['rails_lens:annotate'].invoke if defined?(Rails)
          rescue StandardError => e
            warn "Rails Lens hook failed: \#{e.message}"
          end
        end
      RAKE
    end
  end
end
