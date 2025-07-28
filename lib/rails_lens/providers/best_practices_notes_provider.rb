# frozen_string_literal: true

module RailsLens
  module Providers
    class BestPracticesNotesProvider < NotesProviderBase
      def analyzer_class
        Analyzers::BestPracticesAnalyzer
      end
    end
  end
end
