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

      def handle_database_error(error)
        ErrorReporter.report(error, {
                               analyzer: self.class.name,
                               model: model_class.name,
                               table: model_class.table_name
                             })
        []
      end

      def handle_method_error(error)
        # These are likely bugs in our code, so we should log them prominently
        ErrorReporter.report(error, {
                               analyzer: self.class.name,
                               model: model_class.name,
                               method: error.name
                             })
        []
      end

      def handle_unexpected_error(error)
        ErrorReporter.report(error, {
                               analyzer: self.class.name,
                               model: model_class.name,
                               type: 'unexpected'
                             })
        []
      end

      def safe_call(default = nil)
        yield
      rescue ActiveRecord::StatementInvalid => e
        ErrorReporter.report(e, {
                               analyzer: self.class.name,
                               model: model_class.name,
                               operation: 'database_query'
                             })
        default
      rescue NoMethodError, NameError => e
        ErrorReporter.report(e, {
                               analyzer: self.class.name,
                               model: model_class.name,
                               operation: 'method_call'
                             })
        default
      end
    end
  end
end
