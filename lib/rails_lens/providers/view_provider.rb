# frozen_string_literal: true

module RailsLens
  module Providers
    class ViewProvider < SectionProviderBase
      def applicable?(model_class)
        # Only applicable for models backed by views
        ModelDetector.view_exists?(model_class)
      end

      def process(model_class, connection = nil)
        view_metadata = ViewMetadata.new(model_class)

        return nil unless view_metadata.view_exists?

        {
          title: '[view]',
          content: generate_view_content(view_metadata)
        }
      end

      private

      def generate_view_content(view_metadata)
        lines = []

        # View type (regular or materialized)
        lines << "type = \"#{view_metadata.view_type}\"" if view_metadata.view_type

        # Updatable status
        lines << "updatable = #{view_metadata.updatable?}"

        # Dependencies
        dependencies = view_metadata.dependencies
        if dependencies.any?
          lines << "dependencies = [#{dependencies.map { |d| "\"#{d}\"" }.join(', ')}]"
        end

        # Refresh strategy for materialized views
        if view_metadata.materialized_view? && view_metadata.refresh_strategy
          lines << "refresh_strategy = \"#{view_metadata.refresh_strategy}\""
        end

        # Last refreshed timestamp for materialized views
        if view_metadata.materialized_view? && view_metadata.last_refreshed
          lines << "last_refreshed = \"#{view_metadata.last_refreshed}\""
        end

        lines.join("\n")
      end
    end
  end
end
