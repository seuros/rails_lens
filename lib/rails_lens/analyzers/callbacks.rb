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

      # Callbacks that commonly come from ActiveRecord internals
      INTERNAL_CALLBACKS = %w[
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
            next if inherited_from_base?(callback)

            callback_info = parse_callback(callback, chain_name)
            callbacks << callback_info if callback_info
          end
        end

        callbacks.uniq { |c| [c[:type], c[:method], c[:options]] }
      end

      def internal_callback?(callback)
        filter = callback.filter

        # Proc callbacks from dependent: :destroy or other association callbacks
        return true if filter.is_a?(Proc)

        return false unless filter.is_a?(Symbol)

        filter_name = filter.to_s
        INTERNAL_CALLBACKS.any? { |prefix| filter_name.start_with?(prefix) }
      end

      def inherited_from_base?(callback)
        filter = callback.filter

        # Symbol callbacks - check if method is defined in model or its concerns
        if filter.is_a?(Symbol)
          return false if model_class.instance_methods(false).include?(filter)
          return false if model_class.private_instance_methods(false).include?(filter)

          # Check if defined in included modules (concerns)
          model_class.included_modules.each do |mod|
            next if mod.name.nil?
            next if mod.name.start_with?('ActiveRecord', 'ActiveModel', 'ActiveSupport')

            return false if mod.instance_methods(false).include?(filter)
            return false if mod.private_instance_methods(false).include?(filter)
          end

          true
        else
          # Proc/lambda/object callbacks - assume they're from the model
          false
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
          options[:if] = format_conditions(conditions)
        end

        # Extract :unless condition
        if callback.instance_variable_defined?(:@unless) && callback.instance_variable_get(:@unless).present?
          conditions = callback.instance_variable_get(:@unless)
          options[:unless] = format_conditions(conditions)
        end

        # Extract :on option (for validation and commit callbacks)
        if callback.respond_to?(:options) && callback.options[:on]
          on_value = callback.options[:on]
          options[:on] = Array(on_value).map(&:to_s)
        end

        # Extract :prepend option - check if this callback was prepended
        # In Rails 8, prepended callbacks appear first in the chain
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
            # Check if it's a simple lambda or a Rails internal conditional
            source_location = condition.source_location rescue nil
            if source_location && source_location[0]&.include?('active')
              # Skip Rails internal conditionals
              nil
            else
              'proc'
            end
          when String
            condition
          else
            # Skip internal Rails classes like ActiveSupport::Callbacks::Conditionals::Value
            class_name = condition.class.name rescue nil
            next if class_name&.start_with?('ActiveSupport::Callbacks', 'ActiveRecord')

            class_name
          end
        end.compact
      end

      def format_callbacks(callbacks)
        lines = []
        lines << '[callbacks]'

        # Group by callback type and sort by common order
        grouped = callbacks.group_by { |c| c[:type] }

        # Order: validation, save, create, update, destroy, commit, rollback, touch, initialize, find
        callback_order = %i[
          before_validation after_validation
          before_save around_save after_save
          before_create around_create after_create
          before_update around_update after_update
          before_destroy around_destroy after_destroy
          after_commit after_rollback
          after_touch
          after_initialize after_find
        ]

        callback_order.each do |callback_type|
          type_callbacks = grouped[callback_type]
          next unless type_callbacks&.any?

          # Format as TOML array of inline tables
          formatted = type_callbacks.map { |c| format_single_callback(c) }
          lines << "#{callback_type} = [#{formatted.join(', ')}]"
        end

        lines.join("\n")
      end

      def format_single_callback(callback)
        parts = []
        parts << "method = \"#{escape_toml(callback[:method])}\""

        # Add options
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
