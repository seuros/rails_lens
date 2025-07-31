# frozen_string_literal: true

module RailsLens
  # Manages the pipeline of content providers for generating annotations
  class AnnotationPipeline
    attr_reader :providers

    def initialize
      @providers = []
      register_default_providers
    end

    def register(provider)
      @providers << provider
    end

    def unregister(provider_class)
      @providers.reject! { |p| p.is_a?(provider_class) }
    end

    delegate :clear, to: :@providers

    def process(model_class)
      results = {
        schema: nil,
        sections: [],
        notes: []
      }

      # Use the model's connection pool to manage a single connection for all providers
      model_class.connection_pool.with_connection do |connection|
        @providers.each do |provider|
          next unless provider.applicable?(model_class)

          begin
            result = provider.process(model_class, connection)

            case provider.type
            when :schema
              results[:schema] = result
            when :section
              results[:sections] << result if result
            when :notes
              results[:notes].concat(Array(result))
            end
          rescue ActiveRecord::StatementInvalid => e
            warn "Provider #{provider.class} database error for #{model_class}: #{e.message}"
          rescue ActiveRecord::ConnectionNotDefined => e
            warn "Provider #{provider.class} connection error for #{model_class}: #{e.message}"
          rescue NameError, NoMethodError => e
            warn "Provider #{provider.class} method error for #{model_class}: #{e.message}"
          rescue RailsLens::Error => e
            warn "Provider #{provider.class} rails_lens error for #{model_class}: #{e.message}"
          rescue StandardError => e
            warn "Provider #{provider.class} unexpected error for #{model_class}: #{e.message}"
          end
        end
      end

      results
    end

    private

    def register_default_providers
      # Schema provider (primary content)
      register(Providers::SchemaProvider.new)

      # Section providers (additional structured content)
      register(Providers::ExtensionsProvider.new) if RailsLens.config.extensions[:enabled]
      register(Providers::ViewProvider.new)
      register(Providers::InheritanceProvider.new)
      register(Providers::EnumsProvider.new)
      register(Providers::DelegatedTypesProvider.new)
      register(Providers::CompositeKeysProvider.new)
      register(Providers::DatabaseConstraintsProvider.new)
      register(Providers::GeneratedColumnsProvider.new)

      # Notes providers (analysis and recommendations)
      return unless RailsLens.config.schema[:include_notes]

      register(Providers::ViewNotesProvider.new)
      register(Providers::IndexNotesProvider.new)
      register(Providers::ForeignKeyNotesProvider.new)
      register(Providers::AssociationNotesProvider.new)
      register(Providers::ColumnNotesProvider.new)
      register(Providers::PerformanceNotesProvider.new)
      register(Providers::BestPracticesNotesProvider.new)
      register(Providers::ExtensionNotesProvider.new) if RailsLens.config.extensions[:enabled]
    end
  end
end
