# frozen_string_literal: true

module RailsLens
  module Providers
    # Base class for section providers that wrap analyzers
    class SectionProviderBase < Base
      def type
        :section
      end

      def analyzer_class
        raise NotImplementedError, "#{self.class} must implement #analyzer_class"
      end

      def process(model_class, connection = nil)
        analyzer = analyzer_class.new(model_class)
        content = analyzer.analyze

        return nil unless content

        {
          title: nil, # Analyzers include their own section headers
          content: content
        }
      end
    end
  end
end
