# frozen_string_literal: true

module RailsLens
  # Provides consistent error handling for CLI commands
  module CLIErrorHandler
    def with_error_handling
      yield
    rescue Interrupt
      say "\nOperation cancelled by user", :yellow
      exit 1
    rescue ConfigurationError => e
      handle_configuration_error(e)
    rescue ModelDetectionError => e
      handle_model_error(e)
    rescue DatabaseError => e
      handle_database_error(e)
    rescue AnnotationError => e
      handle_annotation_error(e)
    rescue ExtensionError => e
      handle_extension_error(e)
    rescue StandardError => e
      handle_unexpected_error(e)
    end

    private

    def handle_configuration_error(error)
      say "Configuration Error: #{error.message}", :red
      say 'Please check your .rails-lens.yml file', :yellow
      exit 1
    end

    def handle_model_error(error)
      say "Model Error: #{error.message}", :red
      if options[:verbose]
        say 'Make sure your Rails application is properly loaded', :yellow
        say 'Try running: bundle exec rails_lens annotate', :yellow
      end
      exit 1
    end

    def handle_database_error(error)
      say "Database Error: #{error.message}", :red
      if options[:verbose]
        say 'Possible causes:', :yellow
        say '  - Database server is not running', :yellow
        say '  - Invalid database credentials', :yellow
        say '  - Table does not exist', :yellow
        say '  - Permission denied', :yellow
      end
      exit 1
    end

    def handle_annotation_error(error)
      say "Annotation Error: #{error.message}", :red
      if options[:verbose]
        say 'Failed to annotate one or more files', :yellow
        say 'Check file permissions and syntax', :yellow
      end
      exit 1
    end

    def handle_extension_error(error)
      say "Extension Error: #{error.message}", :red
      return unless options[:verbose]

      say 'An extension failed to load or execute', :yellow
      say 'You can disable extensions in .rails-lens.yml', :yellow

      # Don't exit - extensions are optional
    end

    def handle_unexpected_error(error)
      say "Unexpected Error: #{error.class.name}", :red
      say error.message, :red

      if options[:verbose] || options[:debug]
        say "\nBacktrace:", :yellow
        say error.backtrace.first(10).join("\n"), :yellow
      end

      say "\nPlease report this issue at: https://github.com/your-org/rails_lens/issues", :cyan
      exit 1
    end
  end
end
