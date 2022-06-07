# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Shell
        # Avoid external command calls with `Kernel#system`
        #
        # @example
        #   # bad
        #   system("sleep 1")
        #
        #   # good
        #   sleep 1
        #
        class System < Base
          MSG = "Use pure-ruby code instead of external command execution if possible"

          # Whether matches `system`
          # @!method system?(node)
          # @return [Boolean]
          def_node_matcher :system?, <<~PATTERN
            (send nil? :system ...)
          PATTERN

          def on_send(node)
            return unless system?(node)

            add_offense(node)
          end
        end
      end
    end
  end
end
