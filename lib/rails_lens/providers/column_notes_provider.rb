# frozen_string_literal: true

module RailsLens
  module Providers
    class ColumnNotesProvider < NotesProviderBase
      def analyzer_class
        Analyzers::ColumnAnalyzer
      end
    end
  end
end
