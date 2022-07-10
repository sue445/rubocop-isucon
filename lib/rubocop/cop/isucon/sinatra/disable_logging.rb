# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Sinatra
        # Disable sinatra logging
        #
        # @example
        #   # bad
        #   class App < Sinatra::Base
        #     enable :logging
        #   end
        #
        #   # bad
        #   class App < Sinatra::Base
        #   end
        #
        #   # good
        #   class App < Sinatra::Base
        #     disable :logging
        #   end
        #
        class DisableLogging < Base
          include Mixin::SinatraMethods

          extend AutoCorrector

          MSG = "Disable sinatra logging."

          def_node_matcher :logging_enabled?, <<~PATTERN
            (send nil? :enable (sym :logging))
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            return unless parent_is_sinatra_app?(node)
            return unless logging_enabled?(node)

            add_offense(node) do |corrector|
              perform_autocorrect_for_on_send(corrector: corrector, node: node)
            end
          end

          # @param node [RuboCop::AST::Node]
          def on_class(node)
            return unless subclass_of_sinatra_base?(node)
            return if subclass_of_sinatra_base_contains_logging?(node)

            add_offense(node) do |corrector|
              perform_autocorrect_for_on_class(corrector: corrector, node: node)
            end
          end

          private

          # @param corrector [RuboCop::Cop::Corrector]
          # @param node [RuboCop::AST::Node]
          def perform_autocorrect_for_on_send(corrector:, node:)
            corrector.replace(node, "disable :logging")
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param node [RuboCop::AST::Node]
          def perform_autocorrect_for_on_class(corrector:, node:)
            sinatra_base_node = node.child_nodes[1]

            content = [
              "\n",
              (" " * (node.loc.column + 2)),
              "disable :logging",
            ].join

            corrector.insert_after(sinatra_base_node.loc.expression, content)
          end
        end
      end
    end
  end
end
