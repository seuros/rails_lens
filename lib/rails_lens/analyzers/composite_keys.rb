# frozen_string_literal: true

module RailsLens
  module Analyzers
    class CompositeKeys < Base
      def analyze
        pk = model_class.primary_key
        return nil unless pk.is_a?(Array)

        format_composite_keys(pk)
      rescue ActiveRecord::ConnectionNotEstablished => e
        RailsLens.logger.debug { "No database connection for #{model_class.name}: #{e.message}" }
        nil
      end

      private

      def format_composite_keys(keys)
        lines = ['[composite_pk]']
        lines << "keys = #{TomlFormat.quoted_array(keys)}"
        lines.join("\n")
      end
    end
  end
end
