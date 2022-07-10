# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Sinatra
        # Disable sinatra logger logging
        #
        # @example
        #   # bad
        #   logger.error "Search condition not found"
        #
        #   # good
        #   # no logging
        #
        class Logger < Base
          MSG = "Don't use `logger`"

          extend AutoCorrector

          # @!method logger?(node)
          def_node_matcher :logger?, <<~PATTERN
            (send
              (send nil? :logger)
              {:debug | :error | :fatal | :info | :warn}
              ...
            )
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            return unless logger?(node)

            add_offense(node) do |corrector|
              perform_autocorrect(corrector: corrector, node: node)
            end
          end

          private

          # @param corrector [RuboCop::Cop::Corrector]
          # @param node [RuboCop::AST::Node]
          def perform_autocorrect(corrector:, node:)
            corrector.replace(node, "")
          end
        end
      end
    end
  end
end
