# frozen_string_literal: true

module RailsLens
  module Providers
    class ExtensionNotesProvider < Base
      def type
        :notes
      end

      def applicable?(model_class)
        RailsLens.config.extensions[:enabled] && model_has_table?(model_class)
      end

      def process(model_class)
        results = ExtensionLoader.apply_extensions(model_class)
        results[:notes]
      end
    end
  end
end
