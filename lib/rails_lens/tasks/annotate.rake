# frozen_string_literal: true

namespace :rails_lens do
  desc 'Annotate Rails models with schema information'
  task :annotate, [:models] => :environment do |_t, args|
    require 'rails_lens/schema/annotation_manager'

    options = {
      models: args[:models]&.split(',')
    }

    results = RailsLens::Schema::AnnotationManager.annotate_all(options)

    # Only report sources that actually produced annotations; a registered source with
    # nothing to annotate is noise, not news.
    annotated_by_source = (results[:by_source] || {}).select { |_source_name, count| count.positive? }

    if annotated_by_source.any?
      annotated_by_source.each do |source_name, count|
        puts "Annotated #{count} #{source_name} #{'model'.pluralize(count)}"
      end
    else
      puts "Annotated #{results[:annotated].length} #{'model'.pluralize(results[:annotated].length)}"
    end
    puts "Skipped #{results[:skipped].length} #{'model'.pluralize(results[:skipped].length)}" if results[:skipped].any?
    if results[:failed].any?
      puts "Failed to annotate #{results[:failed].length} #{'model'.pluralize(results[:failed].length)}:"
      results[:failed].each do |failure|
        puts "  - #{failure[:model]}: #{failure[:error]}"
      end
    end
    if options[:models] && results.values_at(:annotated, :skipped, :failed).all?(&:empty?)
      warn "No models matched '#{options[:models].join(', ')}'. The task argument is a " \
           'comma-separated list of model class names, e.g. rails_lens:annotate[User,Admin::Account]. ' \
           'Run rails_lens:annotate without arguments to annotate everything.'
    end
  end

  desc 'Remove all annotations from models'
  task remove: :environment do
    require 'rails_lens/schema/annotation_manager'

    results = RailsLens::Schema::AnnotationManager.remove_all

    removed_by_source = (results[:by_source] || {}).select { |_source_name, count| count.positive? }

    if removed_by_source.any?
      removed_by_source.each do |source_name, count|
        puts "Removed annotations from #{count} #{source_name} #{'model'.pluralize(count)}"
      end
    elsif results[:removed].any?
      puts "Removed annotations from #{results[:removed].length} #{'model'.pluralize(results[:removed].length)}"
    end
    if results[:skipped].any?
      puts "Skipped #{results[:skipped].length} #{'model'.pluralize(results[:skipped].length)} (no annotations)"
    end
    if results[:failed].any?
      puts "Failed to remove annotations from #{results[:failed].length} #{'model'.pluralize(results[:failed].length)}:"
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
