# frozen_string_literal: true

module RailsLens
  module Providers
    class DelegatedTypesProvider < SectionProviderBase
      def analyzer_class
        Analyzers::DelegatedTypes
      end
    end
  end
end
