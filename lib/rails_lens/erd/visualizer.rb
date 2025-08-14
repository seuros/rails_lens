# frozen_string_literal: true

require 'mermaid'

module RailsLens
  module ERD
    class Visualizer
      require_relative 'domain_color_mapper'
      attr_reader :options, :config

      def initialize(options: {})
        @options = options
        @config = RailsLens.config.erd.merge(options.compact.transform_keys(&:to_sym))
      end

      def generate
        models = load_models
        generate_mermaid(models)
      end

      private

      def load_models
        ModelDetector.detect_models(options)
      end

      def generate_mermaid(models)
        if models.blank?
          # Still need to save the output even if no models found
          mermaid_output = "erDiagram\n  %% No models found"
          return save_output(mermaid_output, 'mmd')
        end

        # Create new ERDiagram using mermaid-ruby gem
        diagram = Diagrams::ERDiagram.new

        # Process models and add them to the diagram
        models.each do |model|
          # Skip abstract models
          next if model.abstract_class?

          # Skip models without valid tables/views or columns
          is_view = ModelDetector.view_exists?(model)
          has_data_source = is_view || (model.table_exists? && model.columns.present?)
          next unless has_data_source

          begin
            # Create attributes for the entity
            attributes = []
            model.columns.each do |column|
              type_str = format_column_type(column)
              keys = determine_keys(model, column)

              attributes << {
                type: type_str,
                name: column.name,
                keys: keys
              }
            end

            # Add entity to diagram (model name will be automatically quoted if needed)
            diagram.add_entity(
              name: model.name,
              attributes: attributes
            )

            RailsLens.logger.debug { "Added entity: #{model.name}" } if options[:verbose]
          rescue StandardError => e
            RailsLens.logger.debug { "Warning: Could not add entity #{model.name}: #{e.message}" }
          end

          # Add relationships
          next if model.abstract_class?

          is_view = ModelDetector.view_exists?(model)
          has_data_source = is_view || (model.table_exists? && model.columns.present?)
          next unless has_data_source

          add_model_relationships(diagram, model, models)
        end

        # Generate mermaid syntax using the gem
        mermaid_output = diagram.to_mermaid

        # Save output
        filename = save_output(mermaid_output, 'mmd')

        RailsLens.logger.debug 'ERD generated successfully!'
        filename # Return the filename instead of content
      end

      def format_column_type(column)
        formatter_class = case column.sql_type
                          when /jsonb|uuid|inet|array|tsvector/i
                            PostgresqlColumnTypeFormatter
                          when /json|enum|set|mediumtext|tinyint\(1\)/i
                            MysqlColumnTypeFormatter
                          else
                            ColumnTypeFormatter
                          end

        formatter_class.format(column)
      end

      def determine_keys(model, column)
        keys = []
        keys << :PK if column.name == model.primary_key

        # Check foreign keys
        if model.respond_to?(:reflect_on_all_associations)
          model.reflect_on_all_associations(:belongs_to).each do |assoc|
            keys << :FK if assoc.foreign_key.to_s == column.name
          end
        end

        # Check unique indexes - use UK which will be automatically quoted as comment
        if model.connection.indexes(model.table_name).any? do |idx|
          idx.unique && idx.columns.include?(column.name)
        end && keys.exclude?(:PK)
          keys << :UK
        end

        keys
      end

      def add_model_relationships(diagram, model, models)
        model.reflect_on_all_associations.each do |association|
          next if association.options[:through] # Skip through associations for now
          next if association.polymorphic? # Skip polymorphic associations

          # Check if target model exists and has table
          target_model = nil
          begin
            target_model = association.klass
          rescue NameError, ArgumentError
            next # Skip if class can't be loaded
          end

          next unless target_model && models.include?(target_model)

          # Skip relationships to abstract models
          next if target_model.abstract_class?
          next unless target_model.table_exists? && target_model.columns.present?

          case association.macro
          when :belongs_to
            add_belongs_to_relationship(diagram, model, association, target_model)
          when :has_one
            add_has_one_relationship(diagram, model, association, target_model)
          when :has_many
            add_has_many_relationship(diagram, model, association, target_model)
          when :has_and_belongs_to_many
            add_habtm_relationship(diagram, model, association, target_model)
          end
        end

        # Check for closure_tree self-reference - but only if model is not abstract
        return unless model.respond_to?(:_ct) && !model.abstract_class?

        diagram.add_relationship(
          entity1: model.name,
          entity2: model.name,
          cardinality1: :ZERO_OR_MORE,
          cardinality2: :ZERO_OR_MORE,
          identifying: false,
          label: 'closure_tree'
        )
      end

      def add_belongs_to_relationship(diagram, model, association, target_model)
        diagram.add_relationship(
          entity1: model.name,
          entity2: target_model.name,
          cardinality1: :ZERO_OR_MORE,
          cardinality2: :ONE_ONLY,
          identifying: false,
          label: association.name.to_s
        )
      rescue StandardError => e
        RailsLens.logger.debug do
          "Warning: Could not add belongs_to relationship #{model.name} -> #{association.name}: #{e.message}"
        end
      end

      def add_has_one_relationship(diagram, model, association, target_model)
        diagram.add_relationship(
          entity1: model.name,
          entity2: target_model.name,
          cardinality1: :ONE_ONLY,
          cardinality2: :ZERO_OR_ONE,
          identifying: false,
          label: association.name.to_s
        )
      rescue StandardError => e
        RailsLens.logger.debug do
          "Warning: Could not add has_one relationship #{model.name} -> #{association.name}: #{e.message}"
        end
      end

      def add_has_many_relationship(diagram, model, association, target_model)
        diagram.add_relationship(
          entity1: model.name,
          entity2: target_model.name,
          cardinality1: :ONE_ONLY,
          cardinality2: :ZERO_OR_MORE,
          identifying: false,
          label: association.name.to_s
        )
      rescue StandardError => e
        RailsLens.logger.debug do
          "Warning: Could not add has_many relationship #{model.name} -> #{association.name}: #{e.message}"
        end
      end

      def add_habtm_relationship(diagram, model, association, target_model)
        diagram.add_relationship(
          entity1: model.name,
          entity2: target_model.name,
          cardinality1: :ZERO_OR_MORE,
          cardinality2: :ZERO_OR_MORE,
          identifying: false,
          label: association.name.to_s
        )
      rescue StandardError => e
        RailsLens.logger.debug do
          "Warning: Could not add habtm relationship #{model.name} -> #{association.name}: #{e.message}"
        end
      end

      def save_output(content, extension)
        output_dir = config[:output_dir] || 'doc/erd'
        FileUtils.mkdir_p(output_dir)

        filename = File.join(output_dir, "erd.#{extension}")
        File.write(filename, content)

        RailsLens.logger.debug { "ERD saved to: #{filename}" }
        filename # Return the filename
      end
    end
  end
end
