# frozen_string_literal: true

module RailsLens
  module Extensions
    class ClosureTreeExt < Base
      def self.gem_name
        'closure_tree'
      end

      def self.detect?
        if gem_available?(gem_name)
          require gem_name
          true
        else
          false
        end
      end

      def annotate
        return nil unless model_uses_closure_tree?

        lines = []
        lines << '[closure_tree]'
        lines << "parent_column = \"#{parent_column_name}\""
        lines << "hierarchy_table = \"#{hierarchy_table_name}\""

        lines << "order_column = \"#{order_column}\"" if order_column

        lines << "depth_column = \"#{depth_column}\"" if depth_column && has_column?(depth_column)

        lines.join("\n")
      end

      def notes
        return [] unless model_uses_closure_tree?

        notes = []

        # Check parent column index
        notes << NoteCodes.note(parent_column_name, NoteCodes::INDEX) unless has_index?(parent_column_name)

        # Check hierarchy table existence and indexes
        if hierarchy_table_exists?
          unless has_hierarchy_indexes?
            notes << NoteCodes.note(hierarchy_table_name, NoteCodes::COMP_INDEX)
          end

          unless has_hierarchy_depth_index?
            notes << NoteCodes.note('generations', NoteCodes::INDEX)
          end
        else
          notes << NoteCodes.note(hierarchy_table_name, NoteCodes::MISSING)
        end

        # Check for counter cache
        if should_have_counter_cache? && !has_counter_cache?
          notes << NoteCodes.note('children', NoteCodes::COUNTER_CACHE)
        end

        # Check depth column
        if model_class.respond_to?(:cache_depth?) && model_class.cache_depth? && !has_column?(depth_column)
          notes << NoteCodes.note(depth_column, NoteCodes::DEPTH_CACHE)
        end

        notes
      end

      def erd_additions
        return default_erd_additions unless model_uses_closure_tree?

        {
          relationships: [
            {
              type: 'hierarchy',
              from: table_name,
              to: hierarchy_table_name,
              label: 'closure table',
              style: 'dashed'
            }
          ],
          badges: ['tree'],
          attributes: {
            tree_type: 'closure_tree',
            hierarchy_table: hierarchy_table_name
          }
        }
      end

      private

      def model_uses_closure_tree?
        # Check for both acts_as_tree and has_closure_tree
        (model_class.respond_to?(:acts_as_tree) || model_class.respond_to?(:has_closure_tree)) &&
          model_class.respond_to?(:_ct)
      end

      def parent_column_name
        model_class._ct.parent_column_name
      end

      def hierarchy_table_name
        model_class._ct.hierarchy_table_name
      end

      def order_column
        model_class._ct.order_column
      end

      def depth_column
        "#{model_class._ct.name_column}_depth"
      end

      def hierarchy_table_exists?
        connection.table_exists?(hierarchy_table_name)
      end

      def has_hierarchy_indexes?
        return false unless hierarchy_table_exists?

        indexes = connection.indexes(hierarchy_table_name)
        indexes.any? do |index|
          index.columns.sort == %w[ancestor_id descendant_id].sort
        end
      end

      def has_hierarchy_depth_index?
        return false unless hierarchy_table_exists?

        indexes = connection.indexes(hierarchy_table_name)
        indexes.any? do |index|
          index.columns.include?('generations')
        end
      end

      def should_have_counter_cache?
        # Suggest counter cache for models that likely have many children
        has_many_associations.any? { |a| a.name.to_s.match?(/child|children|descendant/) }
      end

      def has_counter_cache?
        column_names.any? { |col| col.match?(/children_count|descendants_count/) }
      end

      def suggested_counter_cache_name
        'children_count'
      end

      def default_erd_additions
        {
          relationships: [],
          badges: [],
          attributes: {}
        }
      end
    end
  end
end
