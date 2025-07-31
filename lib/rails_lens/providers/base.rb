# frozen_string_literal: true

module RailsLens
  module Providers
    # Base class for all annotation content providers
    class Base
      # Returns the type of content this provider generates
      # :schema - Primary schema information (only one allowed)
      # :section - A named section with structured content
      # :notes - Analysis notes and recommendations
      def type
        raise NotImplementedError, "#{self.class} must implement #type"
      end

      # Returns true if this provider should process the given model
      def applicable?(_model_class)
        true
      end

      # Processes the model and returns content
      # For :schema type - returns a string with the schema content
      # For :section type - returns a hash with { title: String, content: String } or nil
      # For :notes type - returns an array of note strings
      def process(model_class, connection = nil)
        raise NotImplementedError, "#{self.class} must implement #process"
      end

      protected

      def model_has_table?(model_class)
        !model_class.abstract_class? && model_class.table_exists?
      rescue StandardError
        false
      end
    end
  end
end
