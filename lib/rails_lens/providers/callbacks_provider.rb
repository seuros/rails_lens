# frozen_string_literal: true

module RailsLens
  module Providers
    class CallbacksProvider < SectionProviderBase
      def analyzer_class
        Analyzers::Callbacks
      end

      def applicable?(model_class)
        # Only applicable to non-abstract models with callbacks
        return false if model_class.abstract_class?

        # Check if model has any callbacks defined (Rails 8+ uses unified chains)
        RailsLens::Analyzers::Callbacks::CALLBACK_CHAINS.any? do |chain_name|
          chain_method = "_#{chain_name}_callbacks"
          model_class.respond_to?(chain_method) && model_class.public_send(chain_method).present?
        end
      rescue StandardError
        false
      end
    end
  end
end
