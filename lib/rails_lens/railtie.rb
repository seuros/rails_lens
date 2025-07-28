# frozen_string_literal: true

require 'rails/railtie'

module RailsLens
  class Railtie < Rails::Railtie
    railtie_name :rails_lens

    rake_tasks do
      load 'rails_lens/tasks/annotate.rake'
      load 'rails_lens/tasks/erd.rake'
      load 'rails_lens/tasks/schema.rake'
      load 'rails_lens/tasks/routes.rake'
      load 'rails_lens/tasks/mailers.rake'
    end
  end
end
