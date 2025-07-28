# frozen_string_literal: true

namespace :rails_lens do
  namespace :routes do
    desc 'Annotate controller files with route information'
    task annotate: :environment do
      require 'rails_lens/route/annotator'

      annotator = RailsLens::Route::Annotator.new
      changed_files = annotator.annotate_all

      puts "Annotated #{changed_files.length} controller files with route information"
      changed_files.each { |file| puts "  - #{file}" }
    end

    desc 'Remove route annotations from controller files'
    task remove: :environment do
      require 'rails_lens/route/annotator'

      annotator = RailsLens::Route::Annotator.new
      changed_files = annotator.remove_all

      puts "Removed route annotations from #{changed_files.length} controller files"
      changed_files.each { |file| puts "  - #{file}" }
    end
  end
end
