# frozen_string_literal: true

module RailsLens
  module Providers
    # Base class for notes providers that wrap analyzers
    class NotesProviderBase < Base
      def type
        :notes
      end

      def applicable?(model_class)
        # Only applicable to tables, not views
        model_has_table?(model_class) && !ModelDetector.view_exists?(model_class)
      end

      def analyzer_class
        raise NotImplementedError, "#{self.class} must implement #analyzer_class"
      end

      def process(model_class, connection = nil)
        analyzer = analyzer_class.new(model_class)
        analyzer.analyze
      end
    end
  end
end
