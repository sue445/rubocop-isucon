# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Sinatra
        # Disable `request.env['rack.logger']` logging
        #
        # @example
        #   # bad
        #   request.env['rack.logger'].warn 'drop post isu condition request'
        #
        #   # good
        #   # no logging
        class RackLogger < Base
          MSG = "Don't use `request.env['rack.logger']`"

          extend AutoCorrector

          # @!method rack_logger?(node)
          def_node_matcher :rack_logger?, <<~PATTERN
            (send
              (send
                (send
                  (send nil? :request)
                  :env
                )
                :[]
                (str "rack.logger")
              )
              {:debug | :error | :fatal | :info | :warn}
              ...
            )
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            return unless rack_logger?(node)

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
