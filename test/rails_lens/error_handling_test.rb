# frozen_string_literal: true

require 'test_helper'
require 'rails_lens/errors'
require 'rails_lens/analyzers/error_handling'
require 'rails_lens/cli_error_handler'

module RailsLens
  class ErrorHandlingTest < ActiveSupport::TestCase
    def setup
      @original_verbose = RailsLens.verbose
      @original_debug = RailsLens.debug
      @original_raise_on_error = RailsLens.raise_on_error
      RailsLens.verbose = true
      RailsLens.debug = false
      RailsLens.raise_on_error = false
    end

    def teardown
      RailsLens.verbose = @original_verbose
      RailsLens.debug = @original_debug
      RailsLens.raise_on_error = @original_raise_on_error
    end

    def test_error_reporter_logs_with_context
      error = StandardError.new('Test error')
      context = { model: 'User', operation: 'analyze' }

      # Create a real logger that captures output to StringIO
      log_output = StringIO.new
      real_logger = Logger.new(log_output)
      real_logger.level = Logger::ERROR

      Rails.stub(:logger, real_logger) do
        RailsLens::ErrorReporter.report(error, context)
      end

      # Get the logged content
      logged_content = log_output.string

      # Verify the error message includes context
      assert_not_empty logged_content, 'Expected a message to be logged'
      assert_match(/Test error/, logged_content)
      assert_match(/model.*User/, logged_content)
      assert_match(/operation.*analyze/, logged_content)
    end

    def test_error_reporter_handle_method
      context = { test: 'handle_method' }

      # Should return nil and not raise when error occurs
      result = RailsLens::ErrorReporter.handle(context) do
        raise StandardError, 'Handled error'
      end

      assert_nil result
    end

    def test_error_reporter_handle_method_with_raise_on_error
      RailsLens.raise_on_error = true

      assert_raises(StandardError) do
        RailsLens::ErrorReporter.handle({}) do
          raise StandardError, 'Should propagate'
        end
      end
    ensure
      RailsLens.raise_on_error = false
    end

    def test_custom_error_hierarchy
      assert_operator RailsLens::ConfigurationError, :<, RailsLens::Error
      assert_operator RailsLens::ModelNotFoundError, :<, RailsLens::ModelDetectionError
      assert_operator RailsLens::ConnectionError, :<, RailsLens::DatabaseError
      assert_operator RailsLens::ExtensionLoadError, :<, RailsLens::ExtensionError
    end

    def test_analyzer_error_handling_database_error
      analyzer = Class.new do
        include Analyzers::ErrorHandling

        attr_reader :model_class

        def initialize(model_class)
          @model_class = model_class
        end

        def analyze
          raise ActiveRecord::StatementInvalid, 'Table not found'
        end
      end.new(User)

      result = analyzer.safe_analyze

      assert_empty result
    end

    def test_analyzer_error_handling_method_error
      analyzer = Class.new do
        include Analyzers::ErrorHandling

        attr_reader :model_class

        def initialize(model_class)
          @model_class = model_class
        end

        def analyze
          undefined_method_call
        end
      end.new(User)

      result = analyzer.safe_analyze

      assert_empty result
    end

    def test_analyzer_safe_call_with_database_error
      analyzer = Class.new do
        include Analyzers::ErrorHandling

        attr_reader :model_class

        def initialize(model_class)
          @model_class = model_class
        end
      end.new(User)

      result = analyzer.send(:safe_call, 'default') do
        raise ActiveRecord::StatementInvalid
      end

      assert_equal 'default', result
    end

    def test_cli_error_handler_configuration_error
      cli = Class.new do
        include CLIErrorHandler

        attr_reader :exit_code, :messages

        def initialize
          @messages = []
          @exit_code = nil
        end

        def say(message, color = nil)
          @messages << { message: message, color: color }
        end

        def exit(code)
          @exit_code = code
        end

        def options
          { verbose: true }
        end
      end.new

      cli.with_error_handling do
        raise ConfigurationError, 'Invalid config'
      end

      assert_equal 1, cli.exit_code
      assert(cli.messages.any? { |m| m[:message].include?('Configuration Error') })
      assert(cli.messages.any? { |m| m[:color] == :red })
    end

    def test_cli_error_handler_database_error_with_verbose
      cli = Class.new do
        include CLIErrorHandler

        attr_reader :messages

        def initialize
          @messages = []
        end

        def say(message, color = nil)
          @messages << { message: message, color: color }
        end

        def exit(code)
          # No-op for testing
        end

        def options
          { verbose: true }
        end
      end.new

      cli.with_error_handling do
        raise DatabaseError, 'Connection refused'
      end

      # Should show helpful database error messages
      assert(cli.messages.any? { |m| m[:message].include?('Database Error') })
      assert(cli.messages.any? { |m| m[:message].include?('Database server is not running') })
    end
  end
end
