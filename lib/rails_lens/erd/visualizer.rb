# frozen_string_literal: true

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

        output = ['erDiagram']

        # Add theme configuration
        if config[:theme] || config[:colors]
          output << ''
          output << '  %% Theme Configuration'
          add_theme_configuration(output)
          output << ''
        end

        # Choose grouping strategy based on configuration
        grouped_models = if config[:group_by_database]
                           # Group models by database connection
                           group_models_by_database(models)
                         else
                           # Group models by domain (existing behavior)
                           group_models_by_domain(models)
                         end

        # Create color mapper for domains (for future extensibility)
        unless config[:group_by_database]
          domain_list = grouped_models.keys.sort
          @color_mapper = create_domain_color_mapper(domain_list)
        end

        # Add entities
        grouped_models.each do |group_key, group_models|
          if config[:group_by_database]
            output << "  %% Database: #{group_key}"
          elsif group_key != :general
            output << "  %% #{group_key.to_s.humanize} Domain"
          end

          group_models.each do |model|
            model_display_name = format_model_name(model)
            output << "  #{model_display_name} {"

            model.columns.each do |column|
              type_str = format_column_type(column)
              name_str = column.name
              keys = determine_keys(model, column)
              key_str = keys.map(&:to_s).join(' ')

              output << "    #{type_str} #{name_str}#{" #{key_str}" unless key_str.empty?}"
            end

            output << '  }'
            output << ''

            Rails.logger.debug { "Added entity: #{model_display_name}" } if options[:verbose]
          rescue StandardError => e
            Rails.logger.debug { "Warning: Could not add entity #{model.name}: #{e.message}" }
            # Don't add partial entity if there's an error
            # Remove the opening brace line if it was added
            output.pop if output.last&.end_with?(' {')
          end
        end

        # Add relationships
        output << '  %% Relationships'
        models.each do |model|
          add_model_relationships(output, model, models)
        end

        # Generate mermaid syntax
        mermaid_output = output.join("\n")

        # Save output
        filename = save_output(mermaid_output, 'mmd')

        Rails.logger.debug 'ERD generated successfully!'
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

        # Check unique indexes
        if model.connection.indexes(model.table_name).any? do |idx|
          idx.unique && idx.columns.include?(column.name)
        end && keys.exclude?(:PK)
          keys << :UK
        end

        keys
      end

      def add_model_relationships(output, model, models)
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

          case association.macro
          when :belongs_to
            add_belongs_to_relationship(output, model, association, target_model)
          when :has_one
            add_has_one_relationship(output, model, association, target_model)
          when :has_many
            add_has_many_relationship(output, model, association, target_model)
          when :has_and_belongs_to_many
            add_habtm_relationship(output, model, association, target_model)
          end
        end

        # Check for closure_tree self-reference
        return unless model.respond_to?(:_ct)

        output << "  #{format_model_name(model)} }o--o{ #{format_model_name(model)} : \"closure_tree\""
      end

      def add_belongs_to_relationship(output, model, association, target_model)
        output << "  #{format_model_name(model)} }o--|| #{format_model_name(target_model)} : \"#{association.name}\""
      rescue StandardError => e
        Rails.logger.debug do
          "Warning: Could not add belongs_to relationship #{model.name} -> #{association.name}: #{e.message}"
        end
      end

      def add_has_one_relationship(output, model, association, target_model)
        output << "  #{format_model_name(model)} ||--o| #{format_model_name(target_model)} : \"#{association.name}\""
      rescue StandardError => e
        Rails.logger.debug do
          "Warning: Could not add has_one relationship #{model.name} -> #{association.name}: #{e.message}"
        end
      end

      def add_has_many_relationship(output, model, association, target_model)
        output << "  #{format_model_name(model)} ||--o{ #{format_model_name(target_model)} : \"#{association.name}\""
      rescue StandardError => e
        Rails.logger.debug do
          "Warning: Could not add has_many relationship #{model.name} -> #{association.name}: #{e.message}"
        end
      end

      def add_habtm_relationship(output, model, association, target_model)
        output << "  #{format_model_name(model)} }o--o{ #{format_model_name(target_model)} : \"#{association.name}\""
      rescue StandardError => e
        Rails.logger.debug do
          "Warning: Could not add habtm relationship #{model.name} -> #{association.name}: #{e.message}"
        end
      end

      def add_theme_configuration(output)
        # Get default color palette
        default_colors = config[:default_colors] || DomainColorMapper::DEFAULT_COLORS

        # Use first few colors for Mermaid theme
        primary_color = default_colors[0] || 'lightgray'
        secondary_color = default_colors[1] || 'lightblue'
        tertiary_color = default_colors[2] || 'lightcoral'

        # Mermaid theme directives
        output << '  %%{init: {'
        output << '    "theme": "default",'
        output << '    "themeVariables": {'
        output << "      \"primaryColor\": \"#{primary_color}\","
        output << '      "primaryTextColor": "#333",'
        output << '      "primaryBorderColor": "#666",'
        output << '      "lineColor": "#666",'
        output << "      \"secondaryColor\": \"#{secondary_color}\","
        output << "      \"tertiaryColor\": \"#{tertiary_color}\""
        output << '    }'
        output << '  }}%%'
      end

      def group_models_by_database(models)
        grouped = Hash.new { |h, k| h[k] = [] }

        models.each do |model|
          # Get the database name from the model's connection
          db_name = model.connection.pool.db_config.name
          grouped[db_name] << model
        rescue StandardError => e
          Rails.logger.debug { "Warning: Could not determine database for #{model.name}: #{e.message}" }
          grouped['unknown'] << model
        end

        # Sort databases for consistent output
        grouped.sort_by { |db_name, _| db_name.to_s }.to_h
      end

      def group_models_by_domain(models)
        grouped = Hash.new { |h, k| h[k] = [] }

        models.each do |model|
          domain = determine_model_domain(model)
          grouped[domain] << model
        end

        # Sort domains for consistent output
        grouped.sort_by { |domain, _| domain.to_s }.to_h
      end

      def determine_model_domain(model)
        model_name = model.name.downcase

        # Basic domain detection based on common patterns
        return :auth if model_name.match?(/user|account|session|authentication|authorization/)
        return :content if model_name.match?(/post|article|comment|blog|page|content/)
        return :commerce if model_name.match?(/product|order|payment|cart|invoice|transaction/)
        return :core if model_name.match?(/category|tag|setting|configuration|notification/)

        # Default domain
        :general
      end

      def create_domain_color_mapper(domains)
        # Get colors from config or use defaults
        colors = config[:default_colors] || DomainColorMapper::DEFAULT_COLORS
        DomainColorMapper.new(domains, colors: colors)
      end

      def format_model_name(model)
        return model.name unless config[:include_all_databases] || config[:show_database_labels]

        # Get database name from the model's connection
        begin
          db_name = model.connection.pool.db_config.name
          return model.name if db_name == 'primary' # Don't prefix primary database models

          "#{model.name}[#{db_name}]"
        rescue StandardError
          model.name
        end
      end

      def save_output(content, extension)
        output_dir = config[:output_dir] || 'doc/erd'
        FileUtils.mkdir_p(output_dir)

        filename = File.join(output_dir, "erd.#{extension}")
        File.write(filename, content)

        Rails.logger.debug { "ERD saved to: #{filename}" }
        filename # Return the filename
      end
    end
  end
end
