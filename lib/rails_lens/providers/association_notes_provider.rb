# frozen_string_literal: true

module RailsLens
  module Providers
    class AssociationNotesProvider < NotesProviderBase
      def analyzer_class
        Analyzers::AssociationAnalyzer
      end
    end
  end
end
