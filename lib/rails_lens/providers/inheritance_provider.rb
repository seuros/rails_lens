# frozen_string_literal: true

module RailsLens
  module Providers
    class InheritanceProvider < Base
      def type
        :section
      end

      def process(model_class, connection = nil)
        analyzer = Analyzers::Inheritance.new(model_class)
        content = analyzer.analyze

        return nil unless content

        {
          title: nil, # Content already includes section header
          content: content
        }
      end
    end
  end
end
