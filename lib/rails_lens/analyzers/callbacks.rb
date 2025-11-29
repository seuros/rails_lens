# frozen_string_literal: true

module RailsLens
  module Analyzers
    class Callbacks < Base
      # ActiveRecord callback chains (Rails 8+ uses unified chains with kind attribute)
      CALLBACK_CHAINS = %i[
        validation
        save
        create
        update
        destroy
        commit
        rollback
        touch
        initialize
        find
      ].freeze

      # Map kinds to full callback type names
      KIND_PREFIXES = {
        before: 'before_',
        after: 'after_',
        around: 'around_'
      }.freeze

      # Callbacks that commonly come from ActiveRecord internals (symbol-based)
      INTERNAL_CALLBACK_PREFIXES = %w[
        autosave_associated_records_for_
        around_save_collection_association
        _ensure_no_duplicate_errors
        normalize_changed_in_place_attributes
        clear_transaction_record_state
        remember_transaction_record_state
        add_to_transaction
        sync_with_transaction_state
        trigger_transactional_callbacks
      ].freeze

      # Known callback order for formatting output
      CALLBACK_ORDER = %i[
        before_validation after_validation
        before_save around_save after_save
        before_create around_create after_create
        before_update around_update after_update
        before_destroy around_destroy after_destroy
        before_commit around_commit after_commit
        before_rollback around_rollback after_rollback
        after_touch
        after_initialize after_find
      ].freeze

      def analyze
        callbacks = extract_callbacks
        return nil if callbacks.empty?

        format_callbacks(callbacks)
      end

      private

      def extract_callbacks
        callbacks = []

        CALLBACK_CHAINS.each do |chain_name|
          chain_method = "_#{chain_name}_callbacks"
          next unless model_class.respond_to?(chain_method)

          chain = model_class.public_send(chain_method)
          next if chain.nil? || chain.empty?

          chain.each do |callback|
            next if internal_callback?(callback)
            next unless defined_in_model_hierarchy?(callback)

            callback_info = parse_callback(callback, chain_name)
            callbacks << callback_info if callback_info
          end
        end

        # Keep order, dedupe only exact duplicates (same type, method, and options hash)
        seen = Set.new
        callbacks.select do |c|
          key = [c[:type], c[:method], c[:options].to_a.sort]
          seen.add?(key)
        end
      end

      def internal_callback?(callback)
        filter = callback.filter

        case filter
        when Symbol
          filter_name = filter.to_s
          INTERNAL_CALLBACK_PREFIXES.any? { |prefix| filter_name.start_with?(prefix) }
        when Proc
          # Check if proc is from Rails internals (association callbacks, dependent: :destroy)
          source_location = filter.source_location rescue nil
          return false if source_location.nil?

          # Filter out procs defined in activerecord/activesupport gems
          source_file = source_location[0].to_s
          source_file.include?('/activerecord') || source_file.include?('/activesupport')
        else
          false
        end
      end

      def defined_in_model_hierarchy?(callback)
        filter = callback.filter

        case filter
        when Symbol
          # Check if method is defined in the model class itself
          return true if model_class.instance_methods(false).include?(filter)
          return true if model_class.private_instance_methods(false).include?(filter)

          # Check if defined in included concerns (non-Rails modules)
          model_class.included_modules.each do |mod|
            next if mod.name.nil?
            next if mod.name.start_with?('ActiveRecord', 'ActiveModel', 'ActiveSupport')

            return true if mod.instance_methods(false).include?(filter)
            return true if mod.private_instance_methods(false).include?(filter)
          end

          # For STI: check parent classes up to (but not including) ActiveRecord::Base
          klass = model_class.superclass
          while klass && klass < ActiveRecord::Base
            return true if klass.instance_methods(false).include?(filter)
            return true if klass.private_instance_methods(false).include?(filter)
            klass = klass.superclass
          end

          false
        when Proc
          # User-defined procs - already filtered internal ones in internal_callback?
          true
        else
          # Callback objects - assume user-defined
          true
        end
      end

      def parse_callback(callback, chain_name)
        filter = callback.filter
        kind = callback.kind
        options = extract_options(callback)

        method_name = case filter
                      when Symbol
                        filter.to_s
                      when Proc
                        'proc'
                      when String
                        filter
                      else
                        # Callback object
                        filter.class.name.demodulize.underscore
                      end

        # Build full callback type (e.g., :before + :save = :before_save)
        callback_type = "#{KIND_PREFIXES[kind]}#{chain_name}".to_sym

        {
          type: callback_type,
          method: method_name,
          kind: kind,
          options: options
        }
      end

      def extract_options(callback)
        options = {}

        # Extract :if condition
        if callback.instance_variable_defined?(:@if) && callback.instance_variable_get(:@if).present?
          conditions = callback.instance_variable_get(:@if)
          formatted = format_conditions(conditions)
          options[:if] = formatted if formatted.any?
        end

        # Extract :unless condition
        if callback.instance_variable_defined?(:@unless) && callback.instance_variable_get(:@unless).present?
          conditions = callback.instance_variable_get(:@unless)
          formatted = format_conditions(conditions)
          options[:unless] = formatted if formatted.any?
        end

        # Extract :on option (for validation and commit callbacks)
        if callback.respond_to?(:options) && callback.options[:on]
          on_value = callback.options[:on]
          options[:on] = Array(on_value).map(&:to_s)
        end

        # Extract :prepend option
        if callback.respond_to?(:options) && callback.options[:prepend]
          options[:prepend] = true
        end

        options
      end

      def format_conditions(conditions)
        Array(conditions).filter_map do |condition|
          case condition
          when Symbol
            condition.to_s
          when Proc
            source_location = condition.source_location rescue nil
            if source_location.nil?
              'proc'
            elsif source_location[0].to_s.match?(%r{/active(record|support|model)})
              # Skip Rails internal conditionals
              nil
            else
              'proc'
            end
          when String
            condition
          else
            class_name = condition.class.name rescue nil
            # Skip internal Rails callback condition classes
            if class_name&.start_with?('ActiveSupport::Callbacks', 'ActiveRecord')
              nil
            else
              class_name
            end
          end
        end
      end

      def format_callbacks(callbacks)
        lines = []
        lines << '[callbacks]'

        # Group by callback type
        grouped = callbacks.group_by { |c| c[:type] }

        # Output known types in order first
        CALLBACK_ORDER.each do |callback_type|
          type_callbacks = grouped.delete(callback_type)
          next unless type_callbacks&.any?

          formatted = type_callbacks.map { |c| format_single_callback(c) }
          lines << "#{callback_type} = [#{formatted.join(', ')}]"
        end

        # Output any remaining unknown callback types (future Rails versions)
        grouped.each do |callback_type, type_callbacks|
          next unless type_callbacks&.any?

          formatted = type_callbacks.map { |c| format_single_callback(c) }
          lines << "#{callback_type} = [#{formatted.join(', ')}]"
        end

        lines.join("\n")
      end

      def format_single_callback(callback)
        parts = []
        parts << "method = \"#{escape_toml(callback[:method])}\""

        if callback[:options][:if]&.any?
          if_values = callback[:options][:if].map { |v| "\"#{escape_toml(v)}\"" }.join(', ')
          parts << "if = [#{if_values}]"
        end

        if callback[:options][:unless]&.any?
          unless_values = callback[:options][:unless].map { |v| "\"#{escape_toml(v)}\"" }.join(', ')
          parts << "unless = [#{unless_values}]"
        end

        if callback[:options][:on]&.any?
          on_values = callback[:options][:on].map { |v| "\"#{escape_toml(v)}\"" }.join(', ')
          parts << "on = [#{on_values}]"
        end

        parts << 'prepend = true' if callback[:options][:prepend]

        "{ #{parts.join(', ')} }"
      end

      def escape_toml(str)
        str.to_s.gsub('\\', '\\\\').gsub('"', '\\"')
      end
    end
  end
end
