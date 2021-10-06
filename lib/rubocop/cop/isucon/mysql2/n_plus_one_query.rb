# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
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
        #   rows = db.xquery(<<~SQL, schedule_id)
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
        #
        class NPlusOneQuery < Base
          MSG = "This looks like N+1 query."

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L38
          POST_CONDITION_LOOP_TYPES = %i[while_post until_post].freeze

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L39
          LOOP_TYPES = (POST_CONDITION_LOOP_TYPES + %i[while until for]).freeze

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L41
          ENUMERABLE_METHOD_NAMES = (Enumerable.instance_methods + [:each]).to_set.freeze

          def_node_search :find_xquery, <<-PATTERN
            (send (send nil? _) {:xquery | :query} ...)
          PATTERN

          def_node_matcher :csv_loop?, <<~PATTERN
            (block
              (send (const nil? :CSV) :parse ...)
              ...)
          PATTERN

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L68
          def_node_matcher :kernel_loop?, <<~PATTERN
            (block
              (send {nil? (const nil? :Kernel)} :loop)
              ...)
          PATTERN

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L74
          def_node_matcher :enumerable_loop?, <<~PATTERN
            (block
              (send $_ #enumerable_method? ...)
              ...)
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            find_xquery(node) do
              receiver, = *node.children

              next if !receiver.send_type? || !parent_is_loop?(receiver)

              add_offense(receiver)
            end
          end

          private

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L102
          def parent_is_loop?(node)
            node.each_ancestor.any? { |ancestor| loop?(ancestor, node) }
          end

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L106
          def loop?(ancestor, node)
            keyword_loop?(ancestor.type) ||
              kernel_loop?(ancestor) ||
              node_within_enumerable_loop?(node, ancestor) ||
              csv_loop?(ancestor)
          end

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L112
          def keyword_loop?(type)
            LOOP_TYPES.include?(type)
          end

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L116
          def node_within_enumerable_loop?(node, ancestor)
            enumerable_loop?(ancestor) do |receiver|
              receiver != node && !receiver&.descendants&.include?(node)
            end
          end

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L130
          def enumerable_method?(method_name)
            ENUMERABLE_METHOD_NAMES.include?(method_name)
          end
        end
      end
    end
  end
end
