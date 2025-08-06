# frozen_string_literal: true

module RailsLens
  module Extensions
    class Base
      INTERFACE_VERSION = '1.0'

      class << self
        def gem_name
          raise NotImplementedError, "#{self.class.name} must implement .gem_name"
        end

        def detect?
          raise NotImplementedError, "#{self.class.name} must implement .detect?"
        end

        def interface_version
          self::INTERFACE_VERSION
        rescue NameError
          INTERFACE_VERSION
        end

        def compatible?
          required_version = RailsLens.config.extensions[:interface_version]
          Gem::Version.new(interface_version) >= Gem::Version.new(required_version)
        end

        # Helper method for gem-based detection
        def gem_available?(gem_name)
          Gem::Specification.find_by_name(gem_name)
          true
        rescue Gem::LoadError
          false
        end
      end

      attr_reader :model_class

      def initialize(model_class)
        @model_class = model_class
      end

      # Override this method to provide model-specific annotations
      def annotate
        nil
      end

      # Override this method to provide analysis notes
      def notes
        []
      end

      # Override this method to provide ERD additions
      def erd_additions
        {
          relationships: [],
          badges: [],
          attributes: {}
        }
      end

      # Validation helper methods
      def safe_method_call(method_name, default_value = nil)
        return default_value unless respond_to?(method_name)

        send(method_name)
      rescue StandardError => e
        log_method_error(method_name, e)
        default_value
      end

      def validate_array_result(result, method_name = 'unknown')
        return [] unless result.is_a?(Array)

        result.select { |item| item.is_a?(String) }
      rescue StandardError => e
        log_method_error(method_name, e)
        []
      end

      def validate_hash_result(result, required_keys = [], method_name = 'unknown')
        unless result.is_a?(Hash)
          log_method_error(method_name, "Expected Hash, got #{result.class}")
          return required_keys.index_with { |_key| [] }
        end

        # Ensure required keys exist with default values
        required_keys.each do |key|
          result[key] ||= key == :attributes ? {} : []
        end

        result
      rescue StandardError => e
        log_method_error(method_name, e)
        required_keys.index_with { |key| key == :attributes ? {} : [] }
      end

      protected

      # Helper methods for extensions

      def table_name
        model_class.table_name
      end

      def connection
        model_class.connection
      end

      def columns
        @columns ||= connection.columns(table_name)
      end

      def column_names
        @column_names ||= columns.map(&:name)
      end

      def has_column?(column_name)
        column_names.include?(column_name.to_s)
      end

      def indexes
        @indexes ||= connection.indexes(table_name)
      end

      def index_names
        @index_names ||= indexes.map(&:name)
      end

      def has_index?(column_name)
        indexes.any? { |index| index.columns.include?(column_name.to_s) }
      end

      def foreign_keys
        @foreign_keys ||= if connection.respond_to?(:foreign_keys)
                            connection.foreign_keys(table_name)
                          else
                            []
                          end
      end

      def associations
        @associations ||= model_class.reflect_on_all_associations
      end

      def has_many_associations
        associations.select { |a| a.macro == :has_many }
      end

      def belongs_to_associations
        associations.select { |a| a.macro == :belongs_to }
      end

      def has_one_associations
        associations.select { |a| a.macro == :has_one }
      end

      def has_and_belongs_to_many_associations
        associations.select { |a| a.macro == :has_and_belongs_to_many }
      end

      private

      def log_method_error(method_name, error)
        error_reporting = RailsLens.config.extensions[:error_reporting] || :warn
        context = "#{self.class.name}##{method_name} for #{model_class.name}"

        message = case error_reporting
                  when :verbose
                    error.is_a?(String) ? error : "#{error.message}\n#{error.backtrace&.first(3)&.join("\n")}"
                  else
                    error.is_a?(String) ? error : error.message
                  end

        case error_reporting
        when :silent
          # Do nothing
        when :warn
          RailsLens.logger.warn "[RailsLens Extensions] Method failed: #{message} (#{context})"
        when :verbose
          RailsLens.logger.error "[RailsLens Extensions] Method failed: #{message} (#{context})"
        end
      end
    end
  end
end
