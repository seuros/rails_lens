# frozen_string_literal: true

module RailsLens
  # Base class for model sources
  # Model sources provide pluggable discovery of different model types
  # (e.g., ActiveRecord, ActiveCypher, etc.)
  #
  # Gems can register their own model source by defining:
  #   GemName::RailsLensModelSource < RailsLens::ModelSource
  #
  # Example:
  #   module MyOrm
  #     class ModelSource < ::RailsLens::ModelSource
  #       def self.models(options = {})
  #         # Return array of model classes
  #       end
  #
  #       def self.file_patterns
  #         ['app/my_models/**/*.rb']
  #       end
  #
  #       def self.annotate_model(model, options = {})
  #         # Return { status: :annotated/:skipped/:failed, model: name, ... }
  #       end
  #
  #       def self.remove_annotation(model)
  #         # Return { status: :removed/:skipped, model: name, ... }
  #       end
  #     end
  #
  #     RailsLensModelSource = ModelSource
  #   end
  #
  class ModelSource
    class << self
      # Return array of model classes to annotate
      # @param options [Hash] Options passed from CLI
      # @return [Array<Class>] Array of model classes
      def models(_options = {})
        raise NotImplementedError, "#{name} must implement .models"
      end

      # Return file patterns for annotation removal
      # Used when removing annotations by filesystem scan
      # @return [Array<String>] Glob patterns relative to Rails.root
      def file_patterns
        raise NotImplementedError, "#{name} must implement .file_patterns"
      end

      # Annotate a single model
      # @param model [Class] The model class to annotate
      # @param options [Hash] Options passed from CLI
      # @return [Hash] Result with :status (:annotated, :skipped, :failed), :model, :file, :message
      def annotate_model(_model, _options = {})
        raise NotImplementedError, "#{name} must implement .annotate_model"
      end

      # Remove annotation from a single model
      # @param model [Class] The model class
      # @return [Hash] Result with :status (:removed, :skipped), :model, :file
      def remove_annotation(_model)
        raise NotImplementedError, "#{name} must implement .remove_annotation"
      end

      # Human-readable name for this source (used in logging)
      # @return [String]
      def source_name
        name.demodulize.sub(/Source$/, '').underscore.humanize
      end
    end
  end
end
