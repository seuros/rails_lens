# frozen_string_literal: true

module RailsLens
  module Providers
    class ViewProvider < SectionProviderBase
      def applicable?(model_class)
        # Only applicable for models backed by views
        ModelDetector.view_exists?(model_class)
      end

      def process(model_class)
        view_metadata = ViewMetadata.new(model_class)

        return nil unless view_metadata.view_exists?

        {
          title: '== View Information',
          content: generate_view_content(view_metadata)
        }
      end

      private

      def generate_view_content(view_metadata)
        lines = []

        # View type (regular or materialized)
        if view_metadata.view_type
          lines << "View Type: #{view_metadata.view_type}"
        end

        # Updatable status
        lines << "Updatable: #{view_metadata.updatable? ? 'Yes' : 'No'}"

        # Dependencies
        dependencies = view_metadata.dependencies
        if dependencies.any?
          lines << "Dependencies: #{dependencies.join(', ')}"
        end

        # Refresh strategy for materialized views
        if view_metadata.materialized_view? && view_metadata.refresh_strategy
          lines << "Refresh Strategy: #{view_metadata.refresh_strategy}"
        end

        # Last refreshed timestamp for materialized views
        if view_metadata.materialized_view? && view_metadata.last_refreshed
          lines << "Last Refreshed: #{view_metadata.last_refreshed}"
        end

        # View definition (truncated for readability)
        if view_metadata.view_definition
          definition = view_metadata.view_definition
          # Truncate long definitions
          if definition.length > 200
            definition = "#{definition[0..200]}..."
          end
          # Remove extra whitespace and newlines
          definition = definition.gsub(/\s+/, ' ').strip
          lines << "Definition: #{definition}"
        end

        lines.join("\n")
      end
    end
  end
end
