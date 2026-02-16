# frozen_string_literal: true

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
          NoteCodes.note(association.name.to_s, NoteCodes::INVERSE_OF)
        end
      end

      def analyze_n_plus_one_risks
        has_many_associations.map do |association|
          NoteCodes.note(association.name.to_s, NoteCodes::N_PLUS_ONE)
        end
      end

      def analyze_counter_caches
        notes = []

        belongs_to_associations.each do |association|
          next if association.polymorphic?

          if should_have_counter_cache?(association) && !has_counter_cache?(association)
            notes << NoteCodes.note(association.name.to_s, NoteCodes::COUNTER_CACHE)
          end
        end

        notes
      end

      def associations_needing_inverse
        all_associations.select do |association|
          association.options[:inverse_of].nil? &&
            needs_explicit_inverse_of?(association) &&
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
        RailsLens.logger.debug { "Failed to check bidirectional association: #{e.message}" }
        false
      rescue NoMethodError => e
        RailsLens.logger.debug { "Method error checking bidirectional association: #{e.message}" }
        false
      end

      def needs_explicit_inverse_of?(association)
        # Rails can auto-infer inverse_of for vanilla associations
        # Only require explicit inverse_of when using custom options
        association.options[:class_name].present? ||
          association.options[:foreign_key].present? ||
          association.options[:as].present? ||
          association.options[:source].present? ||
          association.options[:through].present?
      end

      def should_have_counter_cache?(association)
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
