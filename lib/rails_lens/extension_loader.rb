# frozen_string_literal: true

module RailsLens
  class ExtensionLoader
    class << self
      def load_extensions
        return [] unless extensions_enabled?

        extensions = []

        # Load built-in extensions
        extensions.concat(load_builtin_extensions)

        # Load gem-provided extensions
        extensions.concat(load_gem_extensions) if autoload_enabled?

        # Load custom extensions
        extensions.concat(load_custom_extensions)

        # Filter out ignored extensions
        extensions.reject { |ext| ignored?(ext) }
      end

      def find_extension_for(_model_class)
        load_extensions.find do |extension_class|
          extension_class.detect? && extension_class.compatible?
        end
      end

      def apply_extensions(model_class)
        results = {
          annotations: [],
          notes: [],
          erd_additions: {
            relationships: [],
            badges: [],
            attributes: {}
          }
        }

        load_extensions.each do |extension_class|
          next unless extension_class.detect?
          next unless extension_class.compatible?

          extension = extension_class.new(model_class)

          # Collect annotations with individual error handling
          begin
            if (annotation = extension.annotate)
              results[:annotations] << annotation
            end
          rescue StandardError => e
            log_extension_method_error(extension_class, 'annotate', e, model_class)
          end

          # Collect notes with individual error handling
          begin
            notes = extension.notes
            results[:notes].concat(notes) if notes.is_a?(Array)
          rescue StandardError => e
            log_extension_method_error(extension_class, 'notes', e, model_class)
          end

          # Collect ERD additions with individual error handling
          begin
            erd = extension.erd_additions
            if erd.is_a?(Hash)
              results[:erd_additions][:relationships].concat(erd[:relationships] || [])
              results[:erd_additions][:badges].concat(erd[:badges] || [])
              results[:erd_additions][:attributes].merge!(erd[:attributes] || {})
            end
          rescue StandardError => e
            log_extension_method_error(extension_class, 'erd_additions', e, model_class)
          end
        rescue StandardError => e
          log_extension_error("Failed to initialize or detect extension #{extension_class}: #{e.message}",
                              extension_class.gem_name)
        end

        results
      end

      private

      def extensions_enabled?
        extensions_config = RailsLens.config.extensions
        extensions_config && extensions_config[:enabled]
      end

      def autoload_enabled?
        extensions_config = RailsLens.config.extensions
        extensions_config && extensions_config[:autoload]
      end

      def ignored?(extension_class)
        extensions_config = RailsLens.config.extensions
        ignored_gems = extensions_config ? extensions_config[:ignore] : []
        ignored_gems.include?(extension_class.gem_name)
      end

      def load_builtin_extensions
        extensions = []

        # Load all Ruby files in the extensions directory
        Dir[File.join(__dir__, 'extensions', '*.rb')].each do |file|
          next if file.end_with?('base.rb') # Skip the base class

          begin
            require file

            # Find the extension class
            basename = File.basename(file, '.rb')
            class_name = basename.split('_').map(&:capitalize).join

            if RailsLens::Extensions.const_defined?(class_name)
              extension_class = RailsLens::Extensions.const_get(class_name)
              if valid_extension?(extension_class)
                extensions << extension_class
              else
                log_extension_error("Builtin extension #{class_name} failed validation", file)
              end
            else
              log_extension_error("Expected class #{class_name} not found", file)
            end
          rescue LoadError, SyntaxError => e
            log_extension_error("Failed to load extension file: #{e.message}", file)
          rescue StandardError => e
            log_extension_error("Unexpected error loading extension: #{e.message}", file)
          end
        end

        extensions
      end

      def load_gem_extensions
        extensions = []

        # Check each loaded gem for RailsLens extensions

        Gem.loaded_specs.each_key do |gem_name|
          # Skip gems that are likely to cause autoload issues
          next if %w[digest openssl uri net json].include?(gem_name)

          # Try to find extension in the gem
          # Use ActiveSupport's camelize for proper Rails-style conversion (e.g., 'activecypher' -> 'ActiveCypher')
          gem_constant_name = gem_name.gsub('-', '_').camelize
          extension_constant_name = "#{gem_constant_name}::RailsLensExtension"

          # First check if the gem constant exists without triggering autoload
          next unless Object.const_defined?(gem_constant_name, false)

          gem_constant = Object.const_get(gem_constant_name)
          next unless gem_constant.is_a?(Module)

          # Then check if it has a RailsLensExtension without triggering autoload
          next unless gem_constant.const_defined?('RailsLensExtension', false)

          extension_class = gem_constant.const_get('RailsLensExtension')
          if valid_extension?(extension_class)
            extensions << extension_class
          else
            log_extension_error("Gem extension #{extension_constant_name} failed validation", gem_name)
          end
        rescue NameError
          # No extension found in this gem - this is normal, not an error
        rescue StandardError => e
          log_extension_error("Error loading gem extension: #{e.message}", gem_name)
        end

        extensions
      end

      def load_custom_extensions
        extensions = []

        custom_paths = RailsLens.config.extensions[:custom_paths]
        custom_paths.each do |path|
          next unless File.directory?(path)

          Dir[File.join(path, '*.rb')].each do |file|
            require file

            # Try to determine the class name from the file
            basename = File.basename(file, '.rb')
            class_name = basename.split('_').map(&:capitalize).join

            # Check in various namespaces
            found = false
            [class_name, "RailsLens::Extensions::#{class_name}"].each do |full_name|
              extension_class = Object.const_get(full_name)
              if valid_extension?(extension_class)
                extensions << extension_class
                found = true
                break
              else
                log_extension_error("Custom extension #{full_name} failed validation", file)
              end
            rescue NameError
              # Try next namespace
            end

            unless found
              log_extension_error(
                "No valid extension class found (tried: #{class_name}, RailsLens::Extensions::#{class_name})", file
              )
            end
          rescue LoadError, SyntaxError => e
            log_extension_error("Failed to load custom extension file: #{e.message}", file)
          rescue StandardError => e
            log_extension_error("Unexpected error loading custom extension: #{e.message}", file)
          end
        end

        extensions
      end

      def valid_extension?(klass)
        klass.is_a?(Class) &&
          klass.respond_to?(:gem_name) &&
          klass.respond_to?(:detect?) &&
          klass.respond_to?(:interface_version) &&
          klass.respond_to?(:compatible?) &&
          klass.compatible?
      end

      def log_extension_error(message, context = nil)
        error_reporting = RailsLens.config.extensions[:error_reporting] || :warn

        case error_reporting
        when :silent
          # Do nothing
        when :warn
          RailsLens.logger.warn "[RailsLens Extensions] #{message}#{" (#{context})" if context}"
        when :verbose
          RailsLens.logger.error "[RailsLens Extensions] #{message}#{" (#{context})" if context}"
        end
      end

      def log_extension_method_error(extension_class, method_name, error, model_class)
        context = "#{extension_class.name}##{method_name} for #{model_class.name}"
        error_reporting = RailsLens.config.extensions[:error_reporting] || :warn

        message = case error_reporting
                  when :verbose
                    "#{error.message}\n#{error.backtrace&.first(5)&.join("\n")}"
                  else
                    error.message
                  end

        log_extension_error("Method failed: #{message}", context)
      end
    end
  end
end
