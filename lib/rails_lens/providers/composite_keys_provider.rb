# frozen_string_literal: true

module RailsLens
  module Providers
    class CompositeKeysProvider < SectionProviderBase
      def analyzer_class
        Analyzers::CompositeKeys
      end
    end
  end
end
