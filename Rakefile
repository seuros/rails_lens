# frozen_string_literal: true

require 'bundler/gem_tasks'

desc 'Run all tests'
task :test do # rubocop:disable Rails/RakeEnvironment
  # One process per file: `ruby file1 file2` only executes file1 (the rest
  # become ARGV), and the multi-database tests assume a fresh boot anyway.
  test_files = Dir['test/**/*_test.rb'].reject { |f| f.include?('test/dummy/') }.sort

  failed = test_files.reject do |file|
    puts "== #{file}"
    system(Gem.ruby, '-Ilib:test', file)
  end

  abort "\n#{failed.length} test file(s) failed:\n#{failed.join("\n")}" if failed.any?
end

task default: :test
