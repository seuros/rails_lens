# frozen_string_literal: true

namespace :rails_lens do
  namespace :schema do
    desc 'Annotate models with database schema information'
    task annotate: :environment do
      require 'rails_lens'

      options = {}
      options[:include_abstract] = true if ENV['INCLUDE_ABSTRACT'] == 'true'

      # Support model filtering via environment variable
      if ENV['MODELS']
        model_list = ENV['MODELS'].split(',').map(&:strip)
        options[:models] = model_list
        puts "Filtering to specific models: #{model_list.join(', ')}"
      end

      options[:verbose] = true # Force verbose mode to see connection management
      results = RailsLens.annotate_models(options)

      if results[:annotated].any?
        puts "Annotated #{results[:annotated].length} models"
        puts '(including abstract classes)' if options[:include_abstract]
      end

      puts "\nSkipped #{results[:skipped].length} models (no changes needed)" if results[:skipped].any?

      if results[:failed].any?
        puts "\nFailed to annotate #{results[:failed].length} models:"
        results[:failed].each do |failure|
          puts "  ✗ #{failure[:model]}: #{failure[:error]}"
        end
      end
    end

    desc 'Remove schema annotations from models'
    task remove: :environment do
      require 'rails_lens'

      puts 'Removing schema annotations...'
      results = RailsLens.remove_annotations

      if results[:removed].any?
        puts "Removed annotations from #{results[:removed].length} models:"
        results[:removed].each { |model| puts "  ✓ #{model}" }
      end

      puts "\nSkipped #{results[:skipped].length} models (no annotations found)" if results[:skipped].any?

      if results[:failed].any?
        puts "\nFailed to process #{results[:failed].length} models:"
        results[:failed].each do |failure|
          puts "  ✗ #{failure[:model]}: #{failure[:error]}"
        end
      end
    end

    desc 'Analyze models and show notes'
    task analyze: :environment do
      require 'rails_lens'

      puts 'Analyzing models...'

      pipeline = RailsLens::AnnotationPipeline.new
      models = RailsLens::ModelDetector.detect_models

      models.each do |model|
        next if model.abstract_class? || !model.table_exists?

        results = pipeline.process(model)
        notes = results[:notes]

        if notes.any?
          puts "\n#{model.name}:"
          notes.uniq.each { |note| puts "  - #{note}" }
        end
      rescue StandardError => e
        puts "\nError analyzing #{model.name}: #{e.message}"
      end
    end

    desc 'List detected extensions'
    task extensions: :environment do
      require 'rails_lens'

      puts 'Detected extensions:'

      extensions = RailsLens::ExtensionLoader.load_extensions
      if extensions.any?
        extensions.each do |ext|
          status = ext.detect? ? '✓ Active' : '○ Inactive'
          version = begin
            ext.interface_version
          rescue StandardError
            'Unknown'
          end
          puts "  #{status} #{ext.gem_name} (interface v#{version})"
        end
      else
        puts '  No extensions detected'
      end

      config = RailsLens.config.extensions
      puts "\nExtension configuration:"
      puts "  Enabled: #{config[:enabled]}"
      puts "  Autoload: #{config[:autoload]}"
      puts "  Interface version: #{config[:interface_version]}"

      puts "  Ignored gems: #{config[:ignore].join(', ')}" if config[:ignore].any?

      puts "  Custom paths: #{config[:custom_paths].join(', ')}" if config[:custom_paths].any?
    end
  end
end
