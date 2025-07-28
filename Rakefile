# frozen_string_literal: true

require 'bundler/gem_tasks'

desc 'Run all tests'
task :test do # rubocop:disable Rails/RakeEnvironment
  test_files = Dir['test/**/*_test.rb'].reject { |f| f.include?('test/dummy/') }

  # Run minitest directly to avoid rake test runner issues
  cmd = "ruby -Ilib:test #{test_files.join(' ')}"

  puts "Running tests with: #{cmd}"
  system(cmd) || exit(1)
end

task default: :test
