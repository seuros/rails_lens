# frozen_string_literal: true

module RailsLens
  module Parsers
    class ParserResult
      attr_reader :classes, :modules, :file_path

      def initialize(classes:, modules:, file_path:)
        @classes = classes
        @modules = modules
        @file_path = file_path
      end

      def find_class(name)
        classes.find { |cls| cls.matches?(name) }
      end

      def find_module(name)
        modules.find { |mod| mod.name == name || mod.full_name == name }
      end

      def class_names
        classes.map(&:full_name)
      end

      def module_names
        modules.map(&:full_name)
      end

      def empty?
        classes.empty? && modules.empty?
      end

      def to_s
        lines = ["File: #{file_path}"]

        unless modules.empty?
          lines << 'Modules:'
          modules.each { |mod| lines << "  #{mod}" }
        end

        unless classes.empty?
          lines << 'Classes:'
          classes.each { |cls| lines << "  #{cls}" }
        end

        lines.join("\n")
      end

      def inspect
        "#<ParserResult file=#{file_path} classes=#{classes.size} modules=#{modules.size}>"
      end
    end
  end
end
