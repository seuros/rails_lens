# frozen_string_literal: true

module RailsLens
  module Providers
    class GeneratedColumnsProvider < SectionProviderBase
      def analyzer_class
        Analyzers::GeneratedColumns
      end
    end
  end
end
