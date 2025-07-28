# frozen_string_literal: true

module RailsLens
  module Providers
    class EnumsProvider < SectionProviderBase
      def analyzer_class
        Analyzers::Enums
      end
    end
  end
end
