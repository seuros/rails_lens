# frozen_string_literal: true

module RailsLens
  module Providers
    class PerformanceNotesProvider < NotesProviderBase
      def analyzer_class
        Analyzers::PerformanceAnalyzer
      end
    end
  end
end
