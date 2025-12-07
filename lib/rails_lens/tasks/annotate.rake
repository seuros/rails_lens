# frozen_string_literal: true

namespace :rails_lens do
  desc 'Annotate Rails models with schema information'
  task :annotate, [:models] => :environment do |_t, args|
    require 'rails_lens/schema/annotation_manager'

    options = {
      models: args[:models]&.split(',')
    }

    results = RailsLens::Schema::AnnotationManager.annotate_all(options)

    if results[:by_source]&.any?
      results[:by_source].each do |source_name, count|
        puts "Annotated #{count} #{source_name} models" if count.positive?
      end
    else
      puts "Annotated #{results[:annotated].length} models"
    end
    puts "Skipped #{results[:skipped].length} models" if results[:skipped].any?
    if results[:failed].any?
      puts "Failed to annotate #{results[:failed].length} models:"
      results[:failed].each do |failure|
        puts "  - #{failure[:model]}: #{failure[:error]}"
      end
    end
  end

  desc 'Remove all annotations from models'
  task remove: :environment do
    require 'rails_lens/schema/annotation_manager'

    results = RailsLens::Schema::AnnotationManager.remove_all

    if results[:by_source]&.any?
      results[:by_source].each do |source_name, count|
        puts "Removed annotations from #{count} #{source_name} models" if count.positive?
      end
    elsif results[:removed].any?
      puts "Removed annotations from #{results[:removed].length} models"
    end
    puts "Skipped #{results[:skipped].length} models (no annotations)" if results[:skipped].any?
    if results[:failed].any?
      puts "Failed to remove annotations from #{results[:failed].length} models:"
      results[:failed].each do |failure|
        puts "  - #{failure[:model]}: #{failure[:error]}"
      end
    end
  end

  desc 'List registered model sources'
  task sources: :environment do
    require 'rails_lens'

    puts 'Registered model sources:'
    RailsLens::ModelSourceLoader.list_sources.each do |source|
      puts "  - #{source[:name]} (#{source[:class]})"
      source[:patterns].each do |pattern|
        puts "      #{pattern}"
      end
    end
  end

  desc 'Annotate all Rails files (models, routes, and mailers)'
  task all: :environment do
    # Annotate models (includes all registered model sources)
    Rake::Task['rails_lens:annotate'].invoke

    # Annotate routes
    Rake::Task['rails_lens:routes:annotate'].invoke

    # Annotate mailers
    Rake::Task['rails_lens:mailers:annotate'].invoke
  end

  desc 'Remove all annotations from Rails files (models, routes, and mailers)'
  task remove_all: :environment do
    # Remove model annotations (includes all registered model sources)
    Rake::Task['rails_lens:remove'].invoke

    # Remove route annotations
    Rake::Task['rails_lens:routes:remove'].invoke

    # Remove mailer annotations
    Rake::Task['rails_lens:mailers:remove'].invoke
  end
end
