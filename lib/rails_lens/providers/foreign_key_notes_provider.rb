# frozen_string_literal: true

module RailsLens
  module Providers
    class ForeignKeyNotesProvider < NotesProviderBase
      def analyzer_class
        Analyzers::ForeignKeyAnalyzer
      end
    end
  end
end
