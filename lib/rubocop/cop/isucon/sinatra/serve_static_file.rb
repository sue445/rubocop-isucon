# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Sinatra
        # TODO: Write cop description and example of bad / good code. For every
        # `SupportedStyle` and unique configuration, there needs to be examples.
        # Examples must have valid Ruby syntax. Do not use upticks.
        #
        # @safety
        #   Delete this section if the cop is not unsafe (`Safe: false` or
        #   `SafeAutoCorrect: false`), or use it to explain how the cop is
        #   unsafe.
        #
        # @example EnforcedStyle: bar (default)
        #   # Description of the `bar` style.
        #
        #   # bad
        #   bad_bar_method
        #
        #   # bad
        #   bad_bar_method(args)
        #
        #   # good
        #   good_bar_method
        #
        #   # good
        #   good_bar_method(args)
        #
        # @example EnforcedStyle: foo
        #   # Description of the `foo` style.
        #
        #   # bad
        #   bad_foo_method
        #
        #   # bad
        #   bad_foo_method(args)
        #
        #   # good
        #   good_foo_method
        #
        #   # good
        #   good_foo_method(args)
        #
        class ServeStaticFile < Base
          MSG = "Serve static files on front server (e.g. nginx)"

          def_node_matcher :file_read_method?, <<~PATTERN
            (send (const nil? :File) :read ...)
          PATTERN

          def_node_matcher :get_method?, <<~PATTERN
            (block (send nil? :get ...) ...)
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            return unless file_read_method?(node)

            parent = parent_get_node(node)
            return unless parent

            return unless end_of_block?(node: node, parent: parent)

            add_offense(node)
          end

          private

          # @param node [RuboCop::AST::Node]
          # @return [RuboCop::AST::Node]
          def parent_get_node(node)
            node.each_ancestor.find { |ancestor| get_method?(ancestor) }
          end

          # @param node [RuboCop::AST::Node]
          # @param parent [RuboCop::AST::Node]
          # @return [Boolean]
          def end_of_block?(node:, parent:)
            parent.child_nodes.last&.child_nodes&.last == node
          end
        end
      end
    end
  end
end
