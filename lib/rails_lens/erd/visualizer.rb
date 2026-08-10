# frozen_string_literal: true

module RailsLens
  module ERD
    class Visualizer
      # Cardinality pair (near-side, far-side) for each association macro.
      RELATIONSHIP_CARDINALITIES = {
        belongs_to: %i[ZERO_OR_MORE ONE_ONLY],
        has_one: %i[ONE_ONLY ZERO_OR_ONE],
        has_many: %i[ONE_ONLY ZERO_OR_MORE],
        has_and_belongs_to_many: %i[ZERO_OR_MORE ZERO_OR_MORE]
      }.freeze

      attr_reader :options, :config

      def initialize(options: {})
        @options = options
        @config = RailsLens.config.erd.merge(options.compact.transform_keys(&:to_sym))
      end

      def generate
        models = load_models
        if config[:group_by_database]
          group_models_by_database(models).map do |db_name, group|
            generate_mermaid(group, basename: "erd_#{db_name}")
          end
        else
          generate_mermaid(models)
        end
      end

      private

      def load_models
        ModelDetector.detect_models(options)
      end

      def group_models_by_database(models)
        models.group_by { |model| model.connection_pool.db_config.name }
      end

      def generate_mermaid(models, basename: 'erd')
        if models.blank?
          # Still need to save the output even if no models found
          mermaid_output = "erDiagram\n  %% No models found"
          return save_output(mermaid_output, 'mmd', basename: basename)
        end

        # Create new ERDiagram using mermaid-ruby gem
        diagram = Diagrams::ERDiagram.new

        # Process models and add them to the diagram
        models.each do |model|
          next unless renderable?(model)

          begin
            # Create attributes for the entity
            attributes = model.columns.map do |column|
              {
                type: format_column_type(column),
                name: column.name,
                keys: determine_keys(model, column)
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

          # Relationships require both entities to exist in the diagram
          add_model_relationships(diagram, model, models) if diagram.entities.key?(model.name)
        end

        # Generate mermaid syntax using the gem
        mermaid_output = diagram.to_mermaid

        # Save output
        filename = save_output(mermaid_output, 'mmd', basename: basename)

        RailsLens.logger.debug 'ERD generated successfully!'
        filename # Return the filename instead of content
      end

      # A model renders when it is concrete and its table/view is reachable;
      # an unavailable connection just drops the model from the diagram.
      def renderable?(model)
        return false if model.abstract_class?

        ModelDetector.view_exists?(model) || (model.table_exists? && model.columns.present?)
      rescue ActiveRecord::ActiveRecordError => e
        RailsLens.logger.debug { "Skipping #{model.name}: #{e.message}" }
        false
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
        # primary_key and foreign_key are arrays for composite keys
        keys << :PK if Array(model.primary_key).include?(column.name)
        keys << :FK if model.reflect_on_all_associations(:belongs_to).any? do |assoc|
          Array(assoc.foreign_key).map(&:to_s).include?(column.name)
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

          # Skip targets whose entity was not added to the diagram
          # (abstract, unreachable connection, or add_entity failed)
          next unless diagram.entities.key?(target_model.name)

          add_association_relationship(diagram, model, association, target_model)
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

      def add_association_relationship(diagram, model, association, target_model)
        cardinality1, cardinality2 = RELATIONSHIP_CARDINALITIES[association.macro]
        return unless cardinality1

        diagram.add_relationship(
          entity1: model.name,
          entity2: target_model.name,
          cardinality1: cardinality1,
          cardinality2: cardinality2,
          identifying: false,
          label: association.name.to_s
        )
      rescue StandardError => e
        RailsLens.logger.debug do
          "Warning: Could not add #{association.macro} relationship #{model.name} -> #{association.name}: #{e.message}"
        end
      end

      def save_output(content, extension, basename: 'erd')
        output_dir = config[:output_dir] || 'doc/erd'
        FileUtils.mkdir_p(output_dir)

        filename = File.join(output_dir, "#{basename}.#{extension}")
        File.write(filename, content)

        RailsLens.logger.debug { "ERD saved to: #{filename}" }
        filename # Return the filename
      end
    end
  end
end
