# frozen_string_literal: true

module RailsLens
  # Discovers and loads model sources from gems
  # Gems can register sources in two ways:
  # 1. Define GemName::RailsLensModelSource (auto-discovery)
  # 2. Call RailsLens::ModelSourceLoader.register(SourceClass) explicitly
  class ModelSourceLoader
    @registered_sources = []

    class << self
      # Register a model source explicitly
      # Use this when gem naming doesn't follow conventions
      # @param source [Class] Model source class
      def register(source)
        return unless valid_source?(source)

        @registered_sources ||= []
        @registered_sources << source unless @registered_sources.include?(source)
      end

      # Load all available model sources
      # @return [Array<Class>] Array of model source classes
      def load_sources
        sources = []

        # Always include ActiveRecord source first
        sources << ModelSources::ActiveRecordSource

        # Include explicitly registered sources
        @registered_sources ||= []
        sources.concat(@registered_sources)

        # Load gem-provided sources via auto-discovery if enabled
        sources.concat(load_gem_sources) if config_enabled?

        # Deduplicate in case a source was both registered and auto-discovered
        sources.uniq
      end

      # List all loaded sources (for debugging/info)
      # @return [Array<Hash>] Source info with name and class
      def list_sources
        load_sources.map do |source|
          {
            name: source.source_name,
            class: source.name,
            patterns: source.file_patterns
          }
        end
      end

      private

      def config_enabled?
        config = RailsLens.config.model_sources
        config && config[:enabled]
      end

      def load_gem_sources
        sources = []

        Gem.loaded_specs.each_key do |gem_name|
          source = find_source_for_gem(gem_name)
          sources << source if source && valid_source?(source)
        end

        sources
      end

      def find_source_for_gem(gem_name)
        # Skip gems that might cause autoload issues
        return nil if %w[digest openssl uri net json].include?(gem_name)

        # Convert gem name to constant (e.g., 'activecypher' -> 'ActiveCypher')
        # Use ActiveSupport's camelize for proper Rails-style conversion
        gem_constant_name = gem_name.gsub('-', '_').camelize

        # Check if gem constant exists without triggering autoload
        return nil unless Object.const_defined?(gem_constant_name, false)

        gem_constant = Object.const_get(gem_constant_name)
        return nil unless gem_constant.is_a?(Module)

        # Check if it has a RailsLensModelSource
        return nil unless gem_constant.const_defined?('RailsLensModelSource', false)

        gem_constant.const_get('RailsLensModelSource')
      rescue NameError
        nil
      rescue StandardError => e
        log_error("Error loading model source from #{gem_name}: #{e.message}")
        nil
      end

      def valid_source?(klass)
        return false unless klass.is_a?(Class)

        required_methods = %i[models file_patterns annotate_model remove_annotation]
        required_methods.all? { |m| klass.respond_to?(m) }
      end

      def log_error(message)
        error_reporting = RailsLens.config.model_sources[:error_reporting] || :warn

        case error_reporting
        when :silent
          # Do nothing
        when :warn
          RailsLens.logger.warn "[RailsLens ModelSources] #{message}"
        when :verbose
          RailsLens.logger.error "[RailsLens ModelSources] #{message}"
        end
      end
    end
  end
end
