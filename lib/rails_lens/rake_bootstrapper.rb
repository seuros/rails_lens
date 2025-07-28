# frozen_string_literal: true

module RailsLens
  class RakeBootstrapper
    class << self
      def call
        require 'rake'
        load './Rakefile' if File.exist?('./Rakefile') && !Rake::Task.task_defined?(:environment)

        begin
          Rake::Task[:environment].invoke
        rescue StandardError
          nil
        end
      end
    end
  end
end
