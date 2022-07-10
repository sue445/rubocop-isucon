# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
        # Use `db.xquery` instead of `db.prepare.execute`
        #
        # @example
        #   # bad (auto-correct isn't possible)
        #   statement = db.prepare('SELECT * FROM `users` WHERE `id` = ?')
        #   statement.execute(
        #     session[:user][:id]
        #   ).first
        #
        #   # bad (auto-correct is possible)
        #   db.prepare('SELECT * FROM `users` WHERE `id` = ?').execute(
        #     session[:user][:id]
        #   ).first
        #
        #   # good
        #   require 'mysql2-cs-bind'
        #
        #   db.xquery('SELECT * FROM `users` WHERE `id` = ?',
        #     session[:user][:id]
        #   ).first
        #
        class PrepareExecute < Base
          extend AutoCorrector

          MSG = "Use `db.xquery` instead of `db.prepare.execute`"

          EXECUTE_LENGTH = "execute".length

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
          # @return [Boolean]
          def_node_matcher :prepare_with_execute?, <<~PATTERN
            (send
              (send
                (send nil? _) :prepare _
              )
              :execute
              ...
            )
          PATTERN

          # @!method prepare?(node)
          # @return [Boolean]
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
                  perform_autocorrect(corrector: corrector, node: node, prepare_arg_node: prepare_arg_node)
                end
              end
              return
            end

            add_offense(node) if prepare_without_execute?(node)
          end

          private

          # @param corrector [RuboCop::Cop::Corrector]
          # @param node [RuboCop::AST::Node]
          # @param prepare_arg_node [RuboCop::AST::Node]
          def perform_autocorrect(corrector:, node:, prepare_arg_node:)
            if node.child_nodes[1]
              perform_autocorrect_for_any_args(corrector: corrector, node: node, prepare_arg_node: prepare_arg_node)
            else
              perform_autocorrect_for_no_args(corrector: corrector, node: node, prepare_arg_node: prepare_arg_node)
            end
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param node [RuboCop::AST::Node]
          # @param prepare_arg_node [RuboCop::AST::Node]
          def perform_autocorrect_for_any_args(corrector:, node:, prepare_arg_node:)
            loc = offence_location(node: node, suffix_length: EXECUTE_LENGTH + 1)
            corrector.replace(loc, "xquery(#{prepare_arg_node.source},")
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param node [RuboCop::AST::Node]
          # @param prepare_arg_node [RuboCop::AST::Node]
          def perform_autocorrect_for_no_args(corrector:, node:, prepare_arg_node:)
            suffix_length =
              if node.source.end_with?("execute()")
                EXECUTE_LENGTH + 2
              else
                EXECUTE_LENGTH
              end
            loc = offence_location(node: node, suffix_length: suffix_length)
            corrector.replace(loc, "xquery(#{prepare_arg_node.source})")
          end

          # @param node [RuboCop::AST::Node]
          # @param suffix_length [Integer]
          # @return [Parser::Source::Rang]
          def offence_location(node:, suffix_length:)
            prepare_begin_pos = node.child_nodes[0].loc.selector.begin_pos
            execute_begin_pos = node.child_nodes[0].loc.end.end_pos + 1
            execute_end_pos = execute_begin_pos + suffix_length

            Parser::Source::Range.new(node.loc.expression.source_buffer, prepare_begin_pos, execute_end_pos)
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
