# frozen_string_literal: true

require 'prism'

module RailsLens
  module Parsers
    class PrismParser
      def self.parse_file(file_path)
        source = File.read(file_path)
        parsed = Prism.parse(source)

        classes = []
        modules = []

        traverse_node(parsed.value, classes, modules)

        ParserResult.new(
          classes: classes,
          modules: modules,
          file_path: file_path
        )
      rescue Prism::ParseError, Errno::ENOENT, IOError
        # Return empty result on parse errors
        ParserResult.new(
          classes: [],
          modules: [],
          file_path: file_path
        )
      end

      def self.traverse_node(node, classes, modules, namespace = [])
        return unless node

        case node
        when Prism::ClassNode
          class_name = extract_constant_name(node.constant_path)

          classes << ClassInfo.new(
            name: class_name,
            line_number: node.location.start_line,
            column: node.location.start_column,
            end_line: node.location.end_line,
            namespace: namespace.join('::').presence
          )

          # Process nested classes and modules
          traverse_children(node, classes, modules, namespace + [class_name])

        when Prism::ModuleNode
          module_name = extract_constant_name(node.constant_path)

          modules << ModuleInfo.new(
            name: module_name,
            line_number: node.location.start_line,
            column: node.location.start_column,
            end_line: node.location.end_line,
            namespace: namespace.join('::').presence
          )

          # Process nested classes and modules
          traverse_children(node, classes, modules, namespace + [module_name])

        else
          # For other node types, recursively traverse children
          traverse_children(node, classes, modules, namespace)
        end
      end

      def self.traverse_children(node, classes, modules, namespace = [])
        return unless node.respond_to?(:child_nodes)

        node.child_nodes.each do |child_node|
          traverse_node(child_node, classes, modules, namespace)
        end
      end

      def self.extract_constant_name(constant_path)
        case constant_path
        when Prism::ConstantReadNode
          constant_path.name.to_s
        when Prism::ConstantPathNode
          # For nested constants like A::B::C, extract the last part
          extract_constant_name(constant_path.child)
        else
          constant_path.to_s
        end
      end
    end
  end
end
