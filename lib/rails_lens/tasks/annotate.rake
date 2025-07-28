# frozen_string_literal: true

namespace :rails_lens do
  desc 'Annotate Rails models with schema information'
  task :annotate, [:models] => :environment do |_t, args|
    require 'rails_lens/schema/annotation_manager'

    options = {
      models: args[:models]&.split(',')
    }

    results = RailsLens::Schema::AnnotationManager.annotate_all(options)

    puts "Annotated #{results[:annotated].length} models"
    puts "Skipped #{results[:skipped].length} models" if results[:skipped].any?
    if results[:failed].any?
      puts "Failed to annotate #{results[:failed].length} models:"
      results[:failed].each do |failure|
        puts "  - #{failure[:model]}: #{failure[:error]}"
      end
    end
  end

  desc 'Annotate all Rails files (models, routes, and mailers)'
  task all: :environment do
    # Annotate models
    Rake::Task['rails_lens:annotate'].invoke

    # Annotate routes
    Rake::Task['rails_lens:routes:annotate'].invoke

    # Annotate mailers
    Rake::Task['rails_lens:mailers:annotate'].invoke
  end
end
