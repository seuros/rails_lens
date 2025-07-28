# frozen_string_literal: true

module RailsLens
  module Providers
    class ExtensionsProvider < Base
      def type
        :section
      end

      def process(model_class)
        results = ExtensionLoader.apply_extensions(model_class)

        return nil if results[:annotations].empty?

        {
          title: '== Extensions',
          content: results[:annotations].join("\n")
        }
      end
    end
  end
end
