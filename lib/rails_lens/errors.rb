# frozen_string_literal: true

module RailsLens
  # Base error class for all Rails Lens errors
  class Error < StandardError; end

  # Configuration-related errors
  class ConfigurationError < Error; end

  # Model detection errors
  class ModelDetectionError < Error; end
  class ModelNotFoundError < ModelDetectionError; end
  class InvalidModelError < ModelDetectionError; end

  # Database-related errors
  class DatabaseError < Error; end
  class ConnectionError < DatabaseError; end
  class SchemaError < DatabaseError; end
  class TableNotFoundError < DatabaseError; end
  class UnsupportedAdapterError < DatabaseError; end

  # Annotation-related errors
  class AnnotationError < Error; end
  class FileNotFoundError < AnnotationError; end
  class ParseError < AnnotationError; end
  class InsertionError < AnnotationError; end

  # Extension-related errors
  class ExtensionError < Error; end
  class ExtensionLoadError < ExtensionError; end
  class ExtensionConfigError < ExtensionError; end

  # Analysis errors
  class AnalysisError < Error; end
  class AnalyzerError < AnalysisError; end

  # ERD generation errors
  class ERDError < Error; end
  class VisualizationError < ERDError; end

  # Error reporter for centralized error handling
  class ErrorReporter
    class << self
      def report(error, context = {})
        return unless RailsLens.verbose || RailsLens.debug

        message = build_error_message(error, context)

        # Use Rails logger for verbose mode
        RailsLens.logger&.error message

        # Use kernel output for debug mode to ensure visibility
        return unless RailsLens.debug

        RailsLens.logger.debug message
      end

      def handle(context = {})
        yield
      rescue StandardError => e
        report(e, context)
        raise if RailsLens.raise_on_error

        nil
      end

      private

      def build_error_message(error, context)
        message = ['[RailsLens Error]']
        message << "Context: #{context.inspect}" if context.any?
        message << "#{error.class}: #{error.message}"
        message << error.backtrace.first(5).join("\n") if error.backtrace && RailsLens.config.debug
        message.join("\n")
      end
    end
  end
end
