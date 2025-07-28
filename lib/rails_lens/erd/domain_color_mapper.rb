# frozen_string_literal: true

module RailsLens
  module ERD
    # Assigns a consistent color to a domain from a predefined palette.
    class DomainColorMapper
      # Default color palette for domains using CSS named colors.
      DEFAULT_COLORS = %w[
        lightblue
        lightcoral
        lightgreen
        lightyellow
        plum
        lightcyan
        lightgray
      ].freeze

      # The color used for domains not found in the initial list.
      FALLBACK_COLOR = 'lightgray'

      # @param domains [Array<Symbol>] A unique list of domain names.
      # @param colors [Array<String>] A list of hex color codes to cycle through.
      def initialize(domains, colors: DEFAULT_COLORS)
        @colors = colors.empty? ? [FALLBACK_COLOR] : colors
        @domain_map = domains.uniq.each_with_index.to_h
      end

      # Returns the color for a given domain.
      #
      # @param domain [Symbol] The domain name.
      # @return [String] The hex color code.
      def color_for(domain)
        domain_index = @domain_map[domain]
        return FALLBACK_COLOR unless domain_index

        @colors[domain_index % @colors.length]
      end
    end
  end
end
