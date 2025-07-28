# frozen_string_literal: true

module RailsLens
  module Providers
    class DatabaseConstraintsProvider < SectionProviderBase
      def analyzer_class
        Analyzers::DatabaseConstraints
      end
    end
  end
end
