# frozen_string_literal: true

require 'test_helper'
require 'rails_lens/cli'

module RailsLens
  class CLITest < ActiveSupport::TestCase
    def setup
      @cli = CLI.new
      @original_stdout = $stdout
      @stdout = StringIO.new
      $stdout = @stdout
    end

    def teardown
      $stdout = @original_stdout

      # Clean up any database connections that might have been established
      ActiveRecord::Base.connection_handler.clear_all_connections!
    end

    def test_version_command
      @cli.version
      output = @stdout.string

      assert_match(/Rails Lens \d+\.\d+\.\d+/, output)
    end

    def test_annotate_default_behavior
      # Mock Schema::AnnotationManager
      mock_results = {
        annotated: %w[User Post Comment],
        skipped: ['ApplicationRecord'],
        failed: []
      }

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:annotate_all, mock_results) do
            result = @cli.annotate
            output = @stdout.string

            assert_equal mock_results, result[:models]
            assert_match(/Annotated 3 models/, output)
            assert_match(/Skipped 1 models/, output)
          end
        end
      end
    end

    def test_annotate_with_specific_models
      mock_results = {
        annotated: %w[User Post],
        skipped: [],
        failed: []
      }

      captured_options = nil

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:annotate_all, lambda { |options|
            captured_options = options
            mock_results
          }) do
            @cli.options = { models: %w[User Post] }
            result = @cli.annotate

            assert_equal %w[User Post], captured_options[:models]
            assert_equal mock_results, result[:models]
          end
        end
      end
    end

    def test_annotate_with_position_option
      captured_options = nil

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:annotate_all, lambda { |options|
            captured_options = options
            { annotated: [], skipped: [], failed: [] }
          }) do
            @cli.options = { position: 'after' }
            @cli.annotate

            assert_equal 'after', captured_options[:position]
          end
        end
      end
    end

    def test_annotate_with_exclude_option
      captured_options = nil

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:annotate_all, lambda { |options|
            captured_options = options
            { annotated: [], skipped: [], failed: [] }
          }) do
            @cli.options = { exclude: ['User'] }
            @cli.annotate

            assert_equal ['User'], captured_options[:exclude]
          end
        end
      end
    end

    def test_annotate_with_force_option
      captured_options = nil

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:annotate_all, lambda { |options|
            captured_options = options
            { annotated: [], skipped: [], failed: [] }
          }) do
            @cli.options = { force: true }
            @cli.annotate

            assert captured_options[:force]
          end
        end
      end
    end

    def test_annotate_all_components
      # Mock all annotators
      mock_model_results = { annotated: ['User'], skipped: [], failed: [] }
      mock_route_results = ['app/controllers/users_controller.rb']
      mock_mailer_results = ['app/mailers/user_mailer.rb']

      mock_route_annotator = Minitest::Mock.new
      mock_route_annotator.expect(:annotate_all, mock_route_results)

      mock_mailer_annotator = Minitest::Mock.new
      mock_mailer_annotator.expect(:annotate_all, mock_mailer_results)

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:annotate_all, mock_model_results) do
            Route::Annotator.stub(:new, mock_route_annotator) do
              Mailer::Annotator.stub(:new, mock_mailer_annotator) do
                @cli.options = { all: true }
                result = @cli.annotate

                assert result[:models]
                assert result[:routes]
                assert result[:mailers]

                mock_route_annotator.verify
                mock_mailer_annotator.verify
              end
            end
          end
        end
      end
    end

    def test_remove_default_behavior
      mock_results = {
        removed: %w[User Post Comment],
        skipped: [],
        failed: []
      }

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:remove_all, mock_results) do
            @cli.options = {}
            result = @cli.remove
            output = @stdout.string

            assert_equal mock_results, result[:models]
            assert_match(/Removed annotations from 3 models/, output)
          end
        end
      end
    end

    def test_remove_with_specific_models
      mock_results = {
        removed: %w[User Post],
        skipped: [],
        failed: []
      }

      # The remove_all method doesn't take options in the current implementation
      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:remove_all, mock_results) do
            @cli.options = { models: %w[User Post] }
            result = @cli.remove

            assert_equal mock_results, result[:models]
          end
        end
      end
    end

    def test_remove_with_dry_run
      # TODO: Implement dry run functionality in remove command
      mock_model_results = { removed: [], skipped: [], failed: [] }

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:remove_all, mock_model_results) do
            output = capture_output do
              @cli.invoke(:remove, [], { 'dry-run' => true })
            end

            assert_match(/removed annotations/i, output)
          end
        end
      end
    end

    def test_remove_all_components
      # Mock all removers
      mock_model_results = { removed: ['User'], skipped: [], failed: [] }
      mock_route_results = ['app/controllers/users_controller.rb']
      mock_mailer_results = ['app/mailers/user_mailer.rb']

      mock_route_annotator = Minitest::Mock.new
      mock_route_annotator.expect(:remove_all, mock_route_results)

      mock_mailer_annotator = Minitest::Mock.new
      mock_mailer_annotator.expect(:remove_all, mock_mailer_results)

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          Schema::AnnotationManager.stub(:remove_all, mock_model_results) do
            Route::Annotator.stub(:new, mock_route_annotator) do
              Mailer::Annotator.stub(:new, mock_mailer_annotator) do
                @cli.options = { all: true }
                result = @cli.remove

                assert result[:models]
                assert result[:routes]
                assert result[:mailers]

                mock_route_annotator.verify
                mock_mailer_annotator.verify
              end
            end
          end
        end
      end
    end

    def test_erd_command
      # Mock ERD::Visualizer
      mock_erd_generator = Minitest::Mock.new
      mock_erd_generator.expect(:generate, 'output/erd.mmd')

      captured_options = nil

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          ERD::Visualizer.stub(:new, lambda { |options|
            captured_options = options
            mock_erd_generator
          }) do
            @cli.options = {}
            @cli.erd
            output = @stdout.string

            # Verify the options were passed correctly
            assert_equal 'output', captured_options[:options][:output_dir]

            assert_match(/Entity Relationship Diagram generated at/, output)
            assert_match(%r{output/erd.mmd}, output)

            mock_erd_generator.verify
          end
        end
      end
    end

    def test_erd_with_custom_output
      mock_erd_generator = Minitest::Mock.new
      mock_erd_generator.expect(:generate, 'custom/dir/erd.mmd')

      captured_options = nil

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          ERD::Visualizer.stub(:new, lambda { |options|
            captured_options = options
            mock_erd_generator
          }) do
            @cli.options = { output: 'custom/dir' }
            @cli.erd
            output = @stdout.string

            assert_equal 'custom/dir', captured_options[:options][:output_dir]
            assert_match(%r{custom/dir/erd.mmd}, output)

            mock_erd_generator.verify
          end
        end
      end
    end

    def test_erd_with_filtering_options
      mock_erd_generator = Minitest::Mock.new
      mock_erd_generator.expect(:generate, 'output/erd.mmd')

      captured_options = nil

      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          ERD::Visualizer.stub(:new, lambda { |options|
            captured_options = options
            mock_erd_generator
          }) do
            @cli.options = {
              only_models: %w[User Post],
              exclude_models: ['ApplicationRecord'],
              include_associations: true
            }
            @cli.erd

            # Check the actual options structure passed to ERD::Visualizer
            assert_equal %w[User Post], captured_options[:options][:only_models]
            assert_equal ['ApplicationRecord'], captured_options[:options][:exclude_models]
            assert captured_options[:options][:include_associations]

            mock_erd_generator.verify
          end
        end
      end
    end

    def test_lint_command
      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          output = capture_output do
            @cli.invoke(:lint, [])
          end

          assert_match(/linting/i, output)
          assert_match(/no linting issues found/i, output)
        end
      end
    end

    def test_lint_with_specific_domains
      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          output = capture_output do
            @cli.invoke(:lint, [], { domains: ['models'] })
          end

          assert_match(/linting/i, output)
        end
      end
    end

    def test_check_command
      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          output = capture_output do
            @cli.invoke(:check, [])
          end

          assert_match(/checking.*configuration/i, output)
        end
      end
    end

    def test_config_command
      RakeBootstrapper.stub(:call, true) do
        @cli.stub(:load_configuration, true) do
          output = capture_output do
            @cli.invoke(:config, ['show'])
          end

          assert_match(/configuration/i, output)
        end
      end
    end

    private

    def capture_output
      @stdout.rewind
      @stdout.truncate(0)
      yield
      @stdout.string
    end
  end
end
