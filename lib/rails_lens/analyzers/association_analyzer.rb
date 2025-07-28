# frozen_string_literal: true

require_relative '../errors'
require_relative 'error_handling'

module RailsLens
  module Analyzers
    class AssociationAnalyzer < Base
      def analyze
        notes = []
        notes.concat(analyze_inverse_of)
        notes.concat(analyze_n_plus_one_risks)
        notes.concat(analyze_counter_caches)
        notes
      end

      private

      def analyze_inverse_of
        associations_needing_inverse.map do |association|
          "Association '#{association.name}' should specify inverse_of"
        end
      end

      def analyze_n_plus_one_risks
        has_many_associations.map do |association|
          # Warn about N+1 query risks for has_many associations
          "Association '#{association.name}' has N+1 query risk. Consider using includes/preload"
        end
      end

      def analyze_counter_caches
        notes = []

        belongs_to_associations.each do |association|
          next if association.polymorphic?

          # Check if the associated model has a matching counter column
          if should_have_counter_cache?(association) && !has_counter_cache?(association)
            notes << "Consider adding counter cache for '#{association.name}'"
          end
        end

        notes
      end

      def associations_needing_inverse
        all_associations.select do |association|
          association.options[:inverse_of].nil? &&
            !association.options[:through] &&
            !association.polymorphic? &&
            bidirectional_association?(association)
        end
      end

      def bidirectional_association?(association)
        return false unless association.klass.respond_to?(:reflect_on_all_associations)

        inverse_types = case association.macro
                        when :belongs_to then %i[has_many has_one]
                        when :has_many then [:belongs_to]
                        when :has_one then [:belongs_to]
                        else []
                        end

        inverse_types.any? do |type|
          association.klass.reflect_on_all_associations(type).any? do |inverse|
            inverse.class_name == model_class.name
          end
        end
      rescue NameError => e
        Rails.logger.debug { "Failed to check bidirectional association: #{e.message}" }
        false
      rescue NoMethodError => e
        Rails.logger.debug { "Method error checking bidirectional association: #{e.message}" }
        false
      end

      def should_have_counter_cache?(association)
        # A counter cache is needed if there is a has_many association
        # on the other side of the belongs_to, and no counter_cache is defined.
        return false unless association.macro == :belongs_to

        inverse_association = association.inverse_of
        return false unless inverse_association && inverse_association.macro == :has_many

        !association.options[:counter_cache]
      end

      def has_counter_cache?(association)
        association.options[:counter_cache].present?
      end

      def column_exists?(column_name)
        model_class.column_names.include?(column_name)
      end

      def all_associations
        model_class.reflect_on_all_associations
      end

      def belongs_to_associations
        model_class.reflect_on_all_associations(:belongs_to)
      end

      def has_many_associations
        model_class.reflect_on_all_associations(:has_many)
      end
    end
  end
end
