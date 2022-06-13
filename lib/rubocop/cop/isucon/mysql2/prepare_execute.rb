# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
        # Use `db.xquery` instead of `db.prepare.execute`
        #
        # @example
        #   # bad
        #   db.prepare('SELECT * FROM `users` WHERE `id` = ?').execute(
        #     session[:user][:id]
        #   ).first
        #
        #   # good
        #   db.xquery('SELECT * FROM `users` WHERE `id` = ?',
        #     session[:user][:id]
        #   ).first
        #
        class PrepareExecute < Base
          extend AutoCorrector

          MSG = "Use `db.xquery` instead of `db.prepare.execute`"

          EXECUTE_LENGTH = "execute(".length

          # @!method find_prepare_execute(node)
          def_node_search :find_prepare_execute, <<~PATTERN
            (send
              (send
                (send nil? _) :prepare $_
              )
              :execute
              ...
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
              find_prepare_execute(node) do |prepare_arg_node|
                add_offense(node) do |corrector|
                  perform_autocorrect(corrector: corrector, current_node: node, prepare_arg_node: prepare_arg_node)
                end
              end
              return
            end

            add_offense(node) if prepare_without_execute?(node)
          end

          private

          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          # @param prepare_arg_node [RuboCop::AST::Node]
          def perform_autocorrect(corrector:, current_node:, prepare_arg_node:)
            loc = offence_location(current_node)
            corrector.replace(loc, "xquery(#{prepare_arg_node.source},")
          end

          # @param current_node [RuboCop::AST::Node]
          def offence_location(current_node)
            prepare_begin_pos = current_node.child_nodes[0].loc.selector.begin_pos
            execute_begin_pos = current_node.child_nodes[0].loc.end.end_pos + 1
            execute_end_pos = execute_begin_pos + EXECUTE_LENGTH

            Parser::Source::Range.new(current_node.loc.expression.source_buffer, prepare_begin_pos, execute_end_pos)
          end

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
