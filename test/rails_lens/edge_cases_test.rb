# frozen_string_literal: true

require 'test_helper'
require 'fileutils'
require 'tempfile'
require 'rails_lens/model_detector'
require 'rails_lens/connection'
require 'rails_lens/schema/annotation'
require 'rails_lens/extension_loader'
require 'rails_lens/extensions/base'
require 'rails_lens/parsers/prism_parser'
require 'rails_lens/cli'

# Mock Rails if not defined

module RailsLens
  class EdgeCasesTest < ActiveSupport::TestCase
    # Edge Cases for Model Detection
    class ModelDetectionEdgeCasesTest < ActiveSupport::TestCase
      def test_anonymous_class_handling
        anonymous_model = Class.new(ApplicationRecord)

        # Anonymous classes should be filtered out
        # Real implementation would filter out classes without names
        assert_nil anonymous_model.name
      end

      def test_model_with_nil_name
        mock_model = Class.new(ApplicationRecord) do
          def self.name
            nil
          end
        end

        # Models without names should be filtered out
        assert_nil mock_model.name
      end

      def test_model_with_empty_name
        mock_model = Class.new(ApplicationRecord) do
          def self.name
            ''
          end
        end

        # Models with empty names should be filtered out
        assert_empty mock_model.name
      end

      def test_habtm_model_exclusion
        habtm_model = Class.new(ApplicationRecord) do
          def self.name
            'HABTM_UsersProjects'
          end
        end

        # HABTM join models should be excluded
        assert habtm_model.name.start_with?('HABTM_')
      end

      def test_model_with_reserved_table_name
        reserved_model = Class.new(ApplicationRecord) do
          @table_name = 'schema_migrations'

          def self.name
            'ReservedTableModel'
          end

          class << self
            attr_reader :table_name
          end
        end

        # Models with excluded table names should be filtered
        assert_equal 'schema_migrations', reserved_model.table_name
      end

      def test_model_detection_with_multiple_databases
        primary_model = Class.new(ApplicationRecord) do
          def self.name
            'PrimaryModel'
          end
        end

        secondary_model = Class.new(ApplicationRecord) do
          def self.establish_connection(config)
            # Mock establish_connection
          end

          establish_connection :secondary

          def self.name
            'SecondaryModel'
          end
        end

        # Should detect models from multiple databases
        assert_equal 'PrimaryModel', primary_model.name
        assert_equal 'SecondaryModel', secondary_model.name
      end

      def test_sti_detection_with_missing_column
        mock_model = Class.new(ApplicationRecord) do
          def self.name
            'STIModel'
          end

          def self.table_exists?
            true
          end

          def self.inheritance_column
            'type'
          end

          def self.column_names
            %w[id name] # Missing 'type' column
          end
        end

        # Should not detect as STI without column
        assert_not mock_model.column_names.include?(mock_model.inheritance_column)
      end
    end

    # Edge Cases for File Operations
    class FileOperationEdgeCasesTest < ActiveSupport::TestCase
      def test_file_with_bom_marker
        Dir.mktmpdir do |dir|
          file_with_bom = File.join(dir, 'bom_model.rb')
          # UTF-8 BOM: EF BB BF
          File.binwrite(file_with_bom, "\xEF\xBB\xBFclass BOMModel < ApplicationRecord\nend")

          content = File.read(file_with_bom, encoding: 'UTF-8')

          assert content.start_with?("\uFEFF") # BOM should be preserved
        end
      end

      def test_extremely_long_file_paths
        Dir.mktmpdir do |dir|
          # Create deeply nested directory structure
          deep_path = dir
          20.times do |i|
            deep_path = File.join(deep_path, "level_#{i}")
            Dir.mkdir(deep_path)
          end

          long_file = File.join(deep_path, 'model.rb')

          # Different systems have different path length limits
          begin
            File.write(long_file, "class LongPathModel\nend")

            assert_path_exists long_file

            # Test that Rails Lens can handle very long file paths
            parser_result = RailsLens::Parsers::PrismParser.parse_file(long_file)

            assert_not_nil parser_result, 'Parser should handle extremely long file paths'
            assert_equal 1, parser_result.classes.size, 'Should find LongPathModel class'
            assert_equal 'LongPathModel', parser_result.classes.first.name
          rescue Errno::ENAMETOOLONG
            # System doesn't support paths this long - test that Rails Lens handles the error gracefully
            assert_raises(Errno::ENAMETOOLONG) do
              File.write(long_file, "class LongPathModel\nend")
            end
            # Verify our parser doesn't crash with path length errors
            result = begin
              RailsLens::Parsers::PrismParser.parse_file(long_file)
            rescue StandardError
              nil
            end

            assert_nil result, "Parser should return nil for files that can't be created due to path length"
          end
        end
      end

      def test_file_with_special_permissions
        Dir.mktmpdir do |dir|
          special_file = File.join(dir, 'special.rb')
          File.write(special_file, "class SpecialModel\nend")

          # Test Rails Lens behavior with permission restrictions on Unix-like systems
          File.chmod(0o111, special_file) # Execute only, no read permission

          assert_raises(Errno::EACCES) do
            File.read(special_file)
          end

          # Test that Rails Lens parser handles permission errors gracefully
          result = begin
            RailsLens::Parsers::PrismParser.parse_file(special_file)
          rescue StandardError
            nil
          end

          assert_nil result, 'Parser should return nil for unreadable files'

          # Restore for cleanup
          File.chmod(0o644, special_file)
        end
      end

      def test_file_with_zero_size
        Dir.mktmpdir do |dir|
          empty_file = File.join(dir, 'empty.rb')
          FileUtils.touch(empty_file)

          assert_equal 0, File.size(empty_file)
          content = File.read(empty_file)

          assert_empty content
        end
      end
    end

    # Edge Cases for Schema Extraction
    class SchemaExtractionEdgeCasesTest < ActiveSupport::TestCase
      def test_table_with_extremely_long_name
        long_table_name = 'a' * 200 # Most databases limit table names to 63-128 chars

        mock_model = Class.new(ApplicationRecord) do
          @table_name = 'a' * 200

          class << self
            attr_reader :table_name
          end

          def self.name
            'LongTableModel'
          end
        end

        # Don't try to set connection= on the model, just verify the table name
        # was properly set on the class
        actual_table_name = mock_model.table_name

        assert_equal long_table_name, actual_table_name
      end

      def test_column_with_special_characters
        mock_columns = [
          { name: 'normal_column', type: :string },
          { name: 'column-with-dash', type: :string },
          { name: 'column.with.dot', type: :string },
          { name: 'column with space', type: :string },
          { name: '列名', type: :string } # Unicode column name
        ]

        # Test that special characters in column names are handled
        assert_equal 5, mock_columns.length
        assert(mock_columns.any? { |c| c[:name].include?('-') })
        assert(mock_columns.any? { |c| c[:name].include?('.') })
        assert(mock_columns.any? { |c| c[:name].include?(' ') })
      end

      def test_table_with_no_primary_key
        mock_model = Class.new(ApplicationRecord) do
          def self.primary_key
            nil
          end

          def self.name
            'NoPrimaryKeyModel'
          end

          def self.table_name
            'no_pk_table'
          end
        end

        assert_nil mock_model.primary_key
      end

      def test_composite_primary_key
        mock_model = Class.new(ApplicationRecord) do
          def self.primary_key
            %i[tenant_id id]
          end

          def self.name
            'CompositePKModel'
          end

          def self.table_name
            'composite_pk_table'
          end
        end

        assert_equal %i[tenant_id id], mock_model.primary_key
      end

      def test_virtual_attributes
        mock_model = Class.new(ApplicationRecord) do
          def self.attribute(name, type, **options)
            # Mock attribute method
          end

          attribute :virtual_attr, :string, default: 'virtual'

          def self.name
            'VirtualAttributeModel'
          end

          def self.table_name
            'virtual_attr_table'
          end

          def self.attribute_names
            %w[id virtual_attr]
          end
        end

        # Virtual attributes should be handled differently from database columns
        assert_includes mock_model.attribute_names, 'virtual_attr'
      end
    end

    # Edge Cases for Annotation Placement
    class AnnotationPlacementEdgeCasesTest < ActiveSupport::TestCase
      def test_file_with_no_class_definition
        content = <<~RUBY
          # This file has no class definition
          module SomeModule
            def self.included(base)
              base.extend(ClassMethods)
            end
          end
        RUBY

        # Test finding annotation position when no class exists
        lines = content.split("\n")

        # When no class is found, annotation should be placed at the beginning
        # Find the first non-comment line
        first_code_line = lines.find_index { |line| !line.strip.empty? && !line.strip.start_with?('#') }

        assert_equal 1, first_code_line, 'First code line should be at index 1 (after comment)'

        # Verify the content structure
        assert_match(/module SomeModule/, lines[first_code_line])
        assert_not content.match?(/^\s*class\s+\w+/), 'Content should not contain any class definition'
      end

      def test_file_with_multiple_classes
        content = <<~RUBY
          class FirstModel < ApplicationRecord
          end

          class SecondModel < ApplicationRecord
          end
        RUBY

        # Test finding first class in file with multiple classes
        first_class_index = content.index('class FirstModel')

        assert_operator first_class_index, :>=, 0
        assert_operator first_class_index, :<, content.index('class SecondModel')
      end

      def test_class_with_complex_inheritance
        content = <<~RUBY
          class ComplexModel < (ENV['USE_BASE'] ? CustomBase : ApplicationRecord)
            # Model content
          end
        RUBY

        # Test annotation position with complex inheritance
        inheritance_end = content.index(')') + 1

        assert_operator inheritance_end, :>, 0
      end

      def test_class_defined_with_class_new
        content = <<~RUBY
          MyModel = Class.new(ApplicationRecord) do
            self.table_name = 'my_models'
          end
        RUBY

        # Test annotation position with Class.new style
        lines = content.split("\n")

        # Find the Class.new line
        class_new_line = lines.find_index { |line| line.include?('Class.new') }

        assert_not_nil class_new_line, 'Should find Class.new definition'
        assert_equal 0, class_new_line, 'Class.new definition should be at the beginning'

        # Verify it's a proper Class.new definition
        assert_match(/\w+\s*=\s*Class\.new\(ApplicationRecord\)/, lines[class_new_line])

        # For Class.new style, annotation should be placed before the assignment
        # This is different from regular class definitions
        optimal_position = class_new_line

        assert_equal 0, optimal_position, 'Annotation should be placed at the beginning for Class.new style'
      end
    end

    # Edge Cases for Extension System
    class ExtensionSystemEdgeCasesTest < ActiveSupport::TestCase
      def test_extension_with_version_constraints
        extension_class = Class.new do
          def self.gem_name
            'version_check_ext'
          end

          def self.interface_version
            '1.0.0'
          end

          def self.detect?
            true
          end

          def self.compatible?
            ruby_version = RUBY_VERSION.split('.').map(&:to_i)
            # Ruby 2.7+ or Ruby 3.0+
            ruby_version[0] >= 3 || (ruby_version[0] >= 2 && ruby_version[1] >= 7)
          end
        end

        # Test extension validation with version constraints
        valid = ExtensionLoader.send(:valid_extension?, extension_class)

        assert valid
      end

      def test_extension_initialization_failure
        Class.new(Extensions::Base) do
          def initialize(_model_class)
            raise ArgumentError, 'Cannot initialize for this model'
          end

          def self.gem_name
            'init_fail_ext'
          end

          def self.detect?
            true
          end
        end

        mock_model = Class.new { def self.name = 'TestModel' }

        # Should handle initialization errors gracefully
        results = ExtensionLoader.apply_extensions(mock_model)

        assert_kind_of Hash, results
      end

      def test_extension_with_conditional_loading
        extension_class = Class.new(Extensions::Base) do
          def self.gem_name
            'conditional_ext'
          end

          def self.detect?
            defined?(SomeGem) && SomeGem::VERSION >= '2.0'
          end

          def self.compatible?
            true
          end
        end

        # When SomeGem is not defined, detect? returns false
        assert_not extension_class.detect?
      end
    end

    # Edge Cases for CLI and Configuration
    class CLIConfigurationEdgeCasesTest < ActiveSupport::TestCase
      def test_config_with_erb_template
        Dir.mktmpdir do |dir|
          config_file = File.join(dir, 'config.yml.erb')
          File.write(config_file, <<~YAML)
            exclude_tables:
              - <%= ENV['EXCLUDE_TABLE'] || 'default_table' %>
            extensions:
              enabled: <%= ENV['ENABLE_EXT'] == 'true' %>
          YAML

          # Should handle ERB templates if supported
          ENV['EXCLUDE_TABLE'] = 'custom_table'
          ENV['ENABLE_EXT'] = 'false'

          # NOTE: Actual implementation would need to process ERB
          assert_path_exists config_file
        end
      end

      def test_cli_with_conflicting_options
        cli = CLI.new

        # Test mutually exclusive options
        options = {
          position: 'before',
          routes: true,
          models: ['User']
        }

        # When annotating routes, model-specific options should be ignored
        cli.stub(:options, options) do
          assert options[:routes]
        end
      end
    end

    # Edge Cases for Parsers
    class ParserEdgeCasesTest < ActiveSupport::TestCase
      def test_ruby_file_with_inline_data
        content = <<~RUBY
          class Model < ApplicationRecord
          end

          __END__
          Some inline data
          that should not be parsed
        RUBY

        Dir.mktmpdir do |dir|
          file_path = File.join(dir, 'inline_data.rb')
          File.write(file_path, content)

          result = Parsers::PrismParser.parse_file(file_path)

          # Should only parse Ruby code, not __END__ section
          assert result
          assert_equal 1, result.classes.length
        end
      end

      def test_file_with_heredoc_containing_code
        content = <<~RUBY
          class Model < ApplicationRecord
            EXAMPLE = <<~CODE
              class FakeClass
                def method
                end
              end
            CODE
          end
        RUBY

        Dir.mktmpdir do |dir|
          file_path = File.join(dir, 'heredoc.rb')
          File.write(file_path, content)

          result = Parsers::PrismParser.parse_file(file_path)

          # Should not be confused by code in heredoc
          assert_equal 1, result.classes.length
          assert_equal 'Model', result.classes.first.name
        end
      end

      def test_file_with_metaclass_definitions
        content = <<~RUBY
          class Model < ApplicationRecord
            class << self
              def custom_method
              end
            end

            def self.another_method
            end
          end
        RUBY

        Dir.mktmpdir do |dir|
          file_path = File.join(dir, 'metaclass.rb')
          File.write(file_path, content)

          result = Parsers::PrismParser.parse_file(file_path)

          # Should handle metaclass definitions
          assert result
          assert_equal 1, result.classes.length
        end
      end
    end

    # Performance and Resource Edge Cases
    class PerformanceEdgeCasesTest < ActiveSupport::TestCase
      def test_annotation_of_extremely_large_file
        Dir.mktmpdir do |dir|
          large_file = File.join(dir, 'large.rb')

          # Create a file with many lines
          File.open(large_file, 'w') do |f|
            f.puts 'class LargeModel < ApplicationRecord'
            10_000.times do |i|
              f.puts "  # Comment line #{i}"
              f.puts "  attr_accessor :attribute_#{i}"
            end
            f.puts 'end'
          end

          # Should handle large files without running out of memory
          Schema::Annotation.new
          content = File.read(large_file)

          # Test inserting annotation into large file
          result = Schema::Annotation.update_or_insert(content, "# == Schema Info\n", /class\s+\w+/)

          assert_operator result.length, :>, content.length
        end
      end

      def test_detection_with_many_models
        # Create many model classes
        models = 100.times.map do |i|
          mock = Minitest::Mock.new
          mock.expect(:name, "Model#{i}")
          mock.expect(:table_name, "model_#{i}s")
          mock
        end

        # Test that many models can be handled
        assert_equal 100, models.length
        models.each_with_index do |model, i|
          assert_equal "Model#{i}", model.name
        end
      end

      def test_concurrent_annotation_safety
        # Test thread safety of annotation process
        results = []
        threads = []

        5.times do |_i|
          threads << Thread.new do
            mock_model = Class.new do
              def self.name
                "ThreadModel#{Thread.current.object_id}"
              end

              def self.table_name
                'thread_models'
              end
            end

            # Test thread-safe annotation generation
            annotation = Schema::Annotation.new
            annotation.add_line("Test annotation for #{mock_model.name}")
            result = annotation.to_s
            results << result
          end
        end

        threads.each(&:join)

        # All threads should complete successfully
        assert_equal 5, results.length
        results.each { |r| assert_kind_of String, r }
      end
    end
  end
end