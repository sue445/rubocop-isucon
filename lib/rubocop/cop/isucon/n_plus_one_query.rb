# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      # Checks that N+1 query is not used
      #
      # @example
      #   # bad
      #   reservations = db.xquery('SELECT * FROM `reservations` WHERE `schedule_id` = ?', schedule_id).map do |reservation|
      #     reservation[:user] = db.xquery('SELECT * FROM `users` WHERE `id` = ? LIMIT 1', id).first
      #     reservation
      #   end
      #
      #   # good
      #   sql = <<~SQL
      #     SELECT
      #       r.id AS reservation_id,
      #       r.schedule_id AS reservation_schedule_id,
      #       r.user_id AS reservation_user_id,
      #       r.created_at AS reservation_created_at,
      #       u.id AS user_id,
      #       u.email AS user_email,
      #       u.nickname AS user_nickname,
      #       u.staff AS user_staff,
      #       u.created_at AS user_created_at
      #     FROM `reservations` AS r
      #     INNER JOIN users u ON u.id = r.user_id
      #     WHERE r.schedule_id = ?
      #   SQL
      #   rows = db.xquery(sql, schedule_id)
      #
      class NPlusOneQuery < Base
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
