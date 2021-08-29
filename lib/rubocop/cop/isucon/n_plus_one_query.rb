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
        MSG = 'This looks like N+1 query.'

        def_node_search :find_xquery, <<-PATTERN
          (send (send nil? _) :xquery (str $_) ...)
        PATTERN

        def on_send(node)
          find_xquery(node) do |sql|
            return unless sql.match?(/^\s*SELECT\s+/i)

            receiver, method, = *node.children

            return unless receiver.send_type?

            # return unless check_literal?(receiver, method) && parent_is_loop?(receiver)
            return unless parent_is_loop?(receiver)

            add_offense(receiver)
          end
        end

        private

        # c.f. https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb
        POST_CONDITION_LOOP_TYPES = %i[while_post until_post].freeze
        LOOP_TYPES = (POST_CONDITION_LOOP_TYPES + %i[while until for]).freeze

        ENUMERABLE_METHOD_NAMES = (Enumerable.instance_methods + [:each]).to_set.freeze
        NONMUTATING_ARRAY_METHODS = %i[& * + - <=> == [] all? any? assoc at
                                       bsearch bsearch_index collect combination
                                       compact count cycle deconstruct difference dig
                                       drop drop_while each each_index empty? eql?
                                       fetch filter find_index first flatten hash
                                       include? index inspect intersection join
                                       last length map max min minmax none? one? pack
                                       permutation product rassoc reject
                                       repeated_combination repeated_permutation reverse
                                       reverse_each rindex rotate sample select shuffle
                                       size slice sort sum take take_while
                                       to_a to_ary to_h to_s transpose union uniq
                                       values_at zip |].freeze

        ARRAY_METHODS = (ENUMERABLE_METHOD_NAMES | NONMUTATING_ARRAY_METHODS).to_set.freeze

        NONMUTATING_HASH_METHODS = %i[< <= == > >= [] any? assoc compact dig
                                      each each_key each_pair each_value empty?
                                      eql? fetch fetch_values filter flatten has_key?
                                      has_value? hash include? inspect invert key key?
                                      keys? length member? merge rassoc rehash reject
                                      select size slice to_a to_h to_hash to_proc to_s
                                      transform_keys transform_values value? values values_at].freeze

        HASH_METHODS = (ENUMERABLE_METHOD_NAMES | NONMUTATING_HASH_METHODS).to_set.freeze

        def_node_matcher :kernel_loop?, <<~PATTERN
          (block
            (send {nil? (const nil? :Kernel)} :loop)
            ...)
        PATTERN

        def_node_matcher :enumerable_loop?, <<~PATTERN
          (block
            (send $_ #enumerable_method? ...)
            ...)
        PATTERN

        def check_literal?(node, method)
          !node.nil? &&
            nonmutable_method_of_array_or_hash?(node, method) &&
            node.children.size >= min_size &&
            node.recursive_basic_literal?
        end

        def nonmutable_method_of_array_or_hash?(node, method)
          (node.array_type? && ARRAY_METHODS.include?(method)) ||
            (node.hash_type? && HASH_METHODS.include?(method))
        end

        def parent_is_loop?(node)
          node.each_ancestor.any? { |ancestor| loop?(ancestor, node) }
        end

        def loop?(ancestor, node)
          keyword_loop?(ancestor.type) ||
            kernel_loop?(ancestor) ||
            node_within_enumerable_loop?(node, ancestor)
        end

        def keyword_loop?(type)
          LOOP_TYPES.include?(type)
        end

        def node_within_enumerable_loop?(node, ancestor)
          enumerable_loop?(ancestor) do |receiver|
            receiver != node && !receiver&.descendants&.include?(node)
          end
        end

        def enumerable_method?(method_name)
          ENUMERABLE_METHOD_NAMES.include?(method_name)
        end
      end
    end
  end
end
