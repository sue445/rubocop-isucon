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
        #   # good
        #   class App < Sinatra::Base
        #     disable :logging
        #   end
        #
        #   # good
        #   class App < Sinatra::Base
        #   end
        #
        class DisableLogging < Base
          extend AutoCorrector

          MSG = "Disable sinatra logging."

          def_node_matcher :logging_enabled?, <<~PATTERN
            (send nil? :enable (sym :logging))
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            return unless logging_enabled?(node)

            add_offense(node) do |corrector|
              perform_autocorrect(corrector, node)
            end
          end

          private

          def perform_autocorrect(corrector, node)
            corrector.replace(node, "disable :logging")
          end
        end
      end
    end
  end
end
