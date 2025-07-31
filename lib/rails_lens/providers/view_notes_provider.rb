# frozen_string_literal: true

module RailsLens
  module Providers
    # View-specific notes provider that wraps the Notes analyzer for views only
    class ViewNotesProvider < Base
      def type
        :notes
      end

      def applicable?(model_class)
        # Only applicable to views
        model_has_table?(model_class) && ModelDetector.view_exists?(model_class)
      end

      def process(model_class, connection = nil)
        analyzer = Analyzers::Notes.new(model_class)
        analyzer.analyze
      end
    end
  end
end
