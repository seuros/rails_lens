# frozen_string_literal: true

module RailsLens
  module Analyzers
    # Mixin for consistent error handling across analyzers
    module ErrorHandling
      def safe_analyze
        analyze
      rescue ActiveRecord::StatementInvalid => e
        handle_database_error(e)
      rescue NameError, NoMethodError => e
        handle_method_error(e)
      rescue StandardError => e
        handle_unexpected_error(e)
      end

      private

      # Report an analyzer error with the shared analyzer/model context plus any
      # call-specific +context+ keys.
      def report_analyzer_error(error, **context)
        ErrorReporter.report(error, { analyzer: self.class.name, model: model_class.name }.merge(context))
      end

      def handle_database_error(error)
        report_analyzer_error(error, table: model_class.table_name)
        []
      end

      def handle_method_error(error)
        # These are likely bugs in our code, so we should log them prominently
        report_analyzer_error(error, method: error.name)
        []
      end

      def handle_unexpected_error(error)
        report_analyzer_error(error, type: 'unexpected')
        []
      end

      def safe_call(default = nil)
        yield
      rescue ActiveRecord::StatementInvalid => e
        report_analyzer_error(e, operation: 'database_query')
        default
      rescue NoMethodError, NameError => e
        report_analyzer_error(e, operation: 'method_call')
        default
      end
    end
  end
end
