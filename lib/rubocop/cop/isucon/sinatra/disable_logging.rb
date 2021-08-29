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
          MSG = "Disable sinatra logging."

          def_node_matcher :logging_enabled?, <<~PATTERN
            (send nil? :enable (sym :logging))
          PATTERN

          def on_send(node)
            return unless logging_enabled?(node)

            add_offense(node)
          end
        end
      end
    end
  end
end
