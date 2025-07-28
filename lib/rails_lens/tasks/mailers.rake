# frozen_string_literal: true

namespace :rails_lens do
  namespace :mailers do
    desc 'Annotate mailer files with mailer information'
    task annotate: :environment do
      require 'rails_lens/mailer/annotator'

      annotator = RailsLens::Mailer::Annotator.new
      changed_files = annotator.annotate_all

      puts "Annotated #{changed_files.length} mailer files with mailer information"
      changed_files.each { |file| puts "  - #{file}" }
    end

    desc 'Remove mailer annotations from mailer files'
    task remove: :environment do
      require 'rails_lens/mailer/annotator'

      annotator = RailsLens::Mailer::Annotator.new
      changed_files = annotator.remove_all

      puts "Removed mailer annotations from #{changed_files.length} mailer files"
      changed_files.each { |file| puts "  - #{file}" }
    end
  end
end
