# frozen_string_literal: true

require_relative '../errors'
require_relative 'error_handling'

module RailsLens
  module Analyzers
    class Inheritance < Base
      def analyze
        results = []

        results << analyze_sti if sti_model?
        results << analyze_delegated_type if delegated_type_model?
        results << analyze_polymorphic if polymorphic_associations?

        return nil if results.empty?

        results.compact.join("\n\n")
      end

      private

      def sti_model?
        return false if model_class.abstract_class?

        # Check if this model uses STI
        model_class.inheritance_column &&
          model_class.column_names.include?(model_class.inheritance_column)
      end

      def delegated_type_model?
        # Check for delegated_type declaration
        model_class.respond_to?(:delegated_type_reflection) &&
          model_class.delegated_type_reflection.present?
      rescue NoMethodError => e
        RailsLens.logger.debug { "Failed to check delegated type for #{model_class.name}: #{e.message}" }
        false
      rescue NameError => e
        RailsLens.logger.debug { "Name error checking delegated type: #{e.message}" }
        false
      end

      def analyze_sti
        lines = []
        lines << '== Inheritance (STI)'
        lines << "Type Column: #{model_class.inheritance_column}"

        # Check if this is a base class or subclass
        if model_class.base_class == model_class
          # This is the base class
          subclasses = find_sti_subclasses
          lines << "Known Subclasses: #{subclasses.join(', ')}" if subclasses.any?
          lines << 'Base Class: Yes'
        else
          # This is a subclass
          lines << "Base Class: #{model_class.base_class.name}"
          lines << "Type Value: #{model_class.sti_name}"

          # Find siblings
          siblings = find_sti_siblings
          lines << "Sibling Classes: #{siblings.join(', ')}" if siblings.any?
        end

        lines.join("\n")
      end

      def analyze_delegated_type
        reflection = model_class.delegated_type_reflection
        return nil unless reflection

        lines = []
        lines << '== Delegated Type'
        lines << "Delegate: #{reflection.name}"
        lines << "Type Column: #{reflection.foreign_type}"
        lines << "ID Column: #{reflection.foreign_key}"

        # Try to find known types
        types = find_delegated_types(reflection)
        lines << "Known Types: #{types.join(', ')}" if types.any?

        lines.join("\n")
      end

      def find_sti_subclasses
        # Find all direct subclasses
        subclasses = []

        ObjectSpace.each_object(Class) do |klass|
          subclasses << klass.name if klass < model_class && klass != model_class && klass.base_class == model_class
        end

        subclasses.sort
      rescue NoMethodError => e
        RailsLens.logger.debug { "Failed to find STI subclasses for #{model_class.name}: #{e.message}" }
        []
      rescue NameError => e
        RailsLens.logger.debug { "Name error finding STI subclasses: #{e.message}" }
        []
      end

      def find_sti_siblings
        return [] unless model_class.base_class != model_class

        siblings = []
        base = model_class.base_class

        ObjectSpace.each_object(Class) do |klass|
          siblings << klass.name if klass < base && klass != model_class && klass.base_class == base
        end

        siblings.sort
      rescue NoMethodError => e
        RailsLens.logger.debug { "Failed to find STI siblings for #{model_class.name}: #{e.message}" }
        []
      rescue NameError => e
        RailsLens.logger.debug { "Name error finding STI siblings: #{e.message}" }
        []
      end

      def find_delegated_types(reflection)
        # Try to find models that could be delegated types
        types = []
        type_column = reflection.foreign_type

        # Look for records in the database to see what types exist
        if model_class.table_exists?
          existing_types = model_class
                           .where.not(type_column => nil)
                           .distinct
                           .pluck(type_column)
                           .compact
                           .sort

          types.concat(existing_types)
        end

        types.uniq.sort
      rescue ActiveRecord::StatementInvalid => e
        RailsLens.logger.debug { "Database error finding delegated types for #{model_class.name}: #{e.message}" }
        []
      rescue ActiveRecord::ConnectionNotEstablished => e
        RailsLens.logger.debug { "No database connection for #{model_class.name}: #{e.message}" }
        []
      end

      def polymorphic_associations?
        model_class.reflect_on_all_associations.any? do |reflection|
          reflection.options[:polymorphic] || reflection.options[:as]
        end
      end

      def analyze_polymorphic
        lines = []
        lines << '== Polymorphic Associations'

        # Find polymorphic belongs_to associations
        polymorphic_belongs_to = model_class.reflect_on_all_associations(:belongs_to).select do |r|
          r.options[:polymorphic]
        end

        if polymorphic_belongs_to.any?
          lines << 'Polymorphic References:'
          polymorphic_belongs_to.each do |reflection|
            lines << "- #{reflection.name} (#{reflection.foreign_type}/#{reflection.foreign_key})"

            # Try to find what types are actually used
            next unless model_class.table_exists? && model_class.columns_hash[reflection.foreign_type.to_s]

            types = find_polymorphic_types(reflection)
            lines << "  Types: #{types.join(', ')}" if types.any?
          end
        end

        # Find associations that reference this model polymorphically
        polymorphic_has_many = model_class.reflect_on_all_associations.select do |r|
          r.options[:as]
        end

        if polymorphic_has_many.any?
          lines << '' if polymorphic_belongs_to.any?
          lines << 'Polymorphic Targets:'
          polymorphic_has_many.each do |reflection|
            as_name = reflection.options[:as]
            lines << "- #{reflection.name} (as: :#{as_name})"
          end
        end

        return nil if lines.size == 1 # Only header

        lines.join("\n")
      end

      def find_polymorphic_types(reflection)
        return [] unless model_class.table_exists?

        type_column = reflection.foreign_type
        model_class
          .where.not(type_column => nil)
          .distinct
          .pluck(type_column)
          .compact
          .sort
      rescue ActiveRecord::StatementInvalid => e
        RailsLens.logger.debug { "Database error finding polymorphic types for #{model_class.name}: #{e.message}" }
        []
      rescue ActiveRecord::ConnectionNotEstablished => e
        RailsLens.logger.debug { "No database connection for #{model_class.name}: #{e.message}" }
        []
      end
    end
  end
end
