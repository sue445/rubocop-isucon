# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
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
        class PrepareExecute < Base
          MSG = "Use `db.xquery` instead of `db.prepare`"

          # @!method find_prepare_execute(node)
          def_node_search :find_prepare_execute, <<~PATTERN
            (send
              (send
                (send nil? _) :prepare _
              )
              :execute
              $...
            )
          PATTERN

          # @!method prepare_with_execute?(node)
          def_node_matcher :prepare_with_execute?, <<~PATTERN
            (send
              (send
                (send nil? _) :prepare _
              )
              :execute
              ...
            )
          PATTERN

          # @!method execute?(node)
          def_node_matcher :prepare?, <<~PATTERN
            (send
              (send nil? _) :prepare _
            )
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            if prepare_with_execute?(node)
              find_prepare_execute(node) do |param_nodes|
                add_offense(node) do |corrector|
                end
              end
              return
            end

            add_offense(node) if prepare_without_execute?(node)
          end

          private

          # Whether `prepare` isn't followed by `execute`
          # @param node [RuboCop::AST::Node]
          # @return [Boolean]
          def prepare_without_execute?(node)
            prepare?(node) && !prepare_with_execute?(node.parent)
          end
        end
      end
    end
  end
end
