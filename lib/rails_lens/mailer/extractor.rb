# frozen_string_literal: true

module RailsLens
  module Mailer
    # Handles extracting mailer information from Rails application
    class Extractor
      class << self
        # Extract all mailer information from Rails application
        #
        # @return [Hash] Mailer information organized by mailer class and method
        def call
          # Check if ActionMailer is available
          return {} unless defined?(ActionMailer::Base)

          mailers = {}

          find_mailer_classes.each do |mailer_class|
            mailer_info = extract_mailer_info(mailer_class)
            next if mailer_info.empty?

            mailers[mailer_class.name] = mailer_info
          end

          mailers
        end

        private

        # Find all mailer classes in the application
        #
        # @return [Array<Class>] Array of mailer classes
        def find_mailer_classes
          return [] unless defined?(ActionMailer::Base)

          # Find all classes that inherit from ActionMailer::Base
          # No need to load files - they should already be loaded
          mailer_classes = []

          ObjectSpace.each_object(Class) do |klass|
            mailer_classes << klass if klass < ActionMailer::Base && klass != ActionMailer::Base
          end

          mailer_classes
        end

        # Extract information for a single mailer class
        #
        # @param mailer_class [Class] Mailer class to analyze
        # @return [Hash] Mailer information
        def extract_mailer_info(mailer_class)
          mailer_info = {}

          # Get mailer methods (exclude inherited ActionMailer methods)
          mailer_methods = mailer_class.instance_methods(false)

          mailer_methods.each do |method_name|
            method_info = extract_method_info(mailer_class, method_name)
            next if method_info.empty?

            mailer_info[method_name.to_s] = method_info
          end

          mailer_info
        end

        # Extract information for a single mailer method
        #
        # @param mailer_class [Class] Mailer class
        # @param method_name [Symbol] Method name
        # @return [Hash] Method information
        def extract_method_info(mailer_class, method_name)
          method_info = {}

          # Get method source location
          method_obj = mailer_class.instance_method(method_name)
          source_location = method_obj.source_location
          return {} unless source_location

          method_info[:source_path] = source_location[0]
          method_info[:line_number] = source_location[1]
          method_info[:class_name] = mailer_class.name

          # Extract templates
          method_info[:templates] = find_templates(mailer_class, method_name)

          # Extract delivery method
          method_info[:delivery_method] = extract_delivery_method(mailer_class)

          # Extract method parameters
          method_info[:parameters] = extract_method_parameters(method_obj)

          # Extract locales (from template files)
          method_info[:locales] = extract_locales(mailer_class, method_name)

          # Extract default values
          method_info[:defaults] = extract_defaults(mailer_class)

          method_info
        end

        # Find template files for a mailer method
        #
        # @param mailer_class [Class] Mailer class
        # @param method_name [Symbol] Method name
        # @return [Array<String>] Template file names
        def find_templates(mailer_class, method_name)
          templates = []
          mailer_name = mailer_class.name.underscore

          # Look for templates in app/views/mailer_name/
          template_dir = Rails.root.join("app/views/#{mailer_name}")
          return templates unless File.directory?(template_dir)

          Dir.glob(template_dir.join("#{method_name}.*")).each do |template_path|
            templates << File.basename(template_path)
          end

          templates.sort
        end

        # Extract delivery method configuration
        #
        # @param mailer_class [Class] Mailer class
        # @return [String] Delivery method name
        def extract_delivery_method(mailer_class)
          delivery_method = mailer_class.delivery_method
          delivery_method ? delivery_method.to_s : 'smtp'
        end

        # Extract method parameters
        #
        # @param method_obj [Method] Method object
        # @return [Array<Hash>] Parameter information
        def extract_method_parameters(method_obj)
          parameters = []

          method_obj.parameters.each do |param_type, param_name|
            param_info = {
              name: param_name.to_s,
              type: param_type.to_s
            }

            parameters << param_info
          end

          parameters
        end

        # Extract available locales for a mailer method
        #
        # @param mailer_class [Class] Mailer class
        # @param method_name [Symbol] Method name
        # @return [Array<String>] Available locales
        def extract_locales(mailer_class, method_name)
          locales = []
          mailer_name = mailer_class.name.underscore

          # Look for locale-specific templates
          template_dir = Rails.root.join("app/views/#{mailer_name}")
          return locales unless File.directory?(template_dir)

          Dir.glob(template_dir.join("#{method_name}.*.erb")).each do |template_path|
            basename = File.basename(template_path, '.erb')
            parts = basename.split('.')

            # Extract locale from filename like "method_name.en.html.erb"
            if parts.length > 2
              locale = parts[1]
              locales << locale unless locales.include?(locale)
            end
          end

          locales.empty? ? ['en'] : locales.sort
        end

        # Extract default mailer settings
        #
        # @param mailer_class [Class] Mailer class
        # @return [Hash] Default settings
        def extract_defaults(mailer_class)
          defaults = {}

          # Extract default from
          if mailer_class.respond_to?(:default) && mailer_class.default[:from]
            defaults[:from] = mailer_class.default[:from]
          end

          # Extract default reply_to
          if mailer_class.respond_to?(:default) && mailer_class.default[:reply_to]
            defaults[:reply_to] = mailer_class.default[:reply_to]
          end

          # Extract layout
          defaults[:layout] = mailer_class._layout if mailer_class.respond_to?(:_layout) && mailer_class._layout

          defaults
        end
      end
    end
  end
end
