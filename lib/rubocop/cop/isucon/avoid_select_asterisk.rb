# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      # Avoid `SELECT *` in `db.xquery`
      #
      # @example
      #   # bad
      #   db.xquery('SELECT * FROM users')
      #
      #   # good
      #   db.xquery('SELECT id, name FROM users')
      #
      class AvoidSelectAsterisk < Base
        # TODO: Implement the cop in here.
        #
        # In many cases, you can use a node matcher for matching node pattern.
        # See https://github.com/rubocop/rubocop-ast/blob/master/lib/rubocop/ast/node_pattern.rb
        #
        # For example
        MSG = 'Use `#good_method` instead of `#bad_method`.'

        def_node_matcher :bad_method?, <<~PATTERN
          (send nil? :bad_method ...)
        PATTERN

        def on_send(node)
          return unless bad_method?(node)

          add_offense(node)
        end
      end
    end
  end
end
