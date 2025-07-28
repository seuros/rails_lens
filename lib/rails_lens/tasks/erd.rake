# frozen_string_literal: true

namespace :rails_lens do
  desc 'Generate Entity Relationship Diagram (Mermaid format)'
  task erd: :environment do
    gem 'mermaid', '>= 0.0.5'
    require 'mermaid'

    puts 'Generating ERD...'
    visualizer = RailsLens::ERD::Visualizer.new
    filename = visualizer.generate
    puts "ERD generated successfully: #{filename}"
    puts ''
    puts 'To view the ERD:'
    puts '1. Install Mermaid CLI: npm install -g @mermaid-js/mermaid-cli'
    puts "2. Generate image: mmdc -i #{filename} -o erd.png"
    puts '3. Or view online: https://mermaid.live/'
  rescue Gem::LoadError
    puts 'Error: Mermaid gem (>= 0.0.5) is required for ERD generation.'
    puts "Add to your Gemfile: gem 'mermaid', '>= 0.0.5'"
    puts 'Then run: bundle install'
    exit 1
  end
end
