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
          include Mixin::Mysql2Methods

          extend AutoCorrector

          MSG = "This looks like N+1 query."

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L38
          POST_CONDITION_LOOP_TYPES = %i[while_post until_post].freeze

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L39
          LOOP_TYPES = (POST_CONDITION_LOOP_TYPES + %i[while until for]).freeze

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L41
          ENUMERABLE_METHOD_NAMES = (Enumerable.instance_methods + [:each]).to_set.freeze

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
            with_xquery(node) do |type, root_gda|
              receiver, = *node.children

              next unless receiver.send_type?

              parent = parent_loop_node(receiver)
              next unless parent

              add_offense(receiver) do |corrector|
                perform_autocorrect(corrector: corrector, current_node: receiver, parent_node: parent, type: type, gda: root_gda)
              end
            end
          end

          private

          def parent_loop_node(node)
            node.each_ancestor.find { |ancestor| loop?(ancestor, node) }
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

          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          # @param parent_node [RuboCop::AST::Node]
          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param gda [RuboCop::Isucon::GDA::Client]
          def perform_autocorrect(corrector:, current_node:, parent_node:, type:, gda:)
            return unless gda
            return unless gda.select_query?

            return unless gda.table_names.count == 1

            parent_receiver = parent_node.child_nodes&.first&.receiver
            return unless parent_receiver.lvar_type?

            return unless gda.where_nodes.count == 1

            where_condition_gda_loc = gda.where_nodes.first.location
            matched = where_condition_gda_loc&.body&.match(/([^\s]+)\s*=\s*\?/)

            return unless matched

            where_column = matched[1]

            # Replace where condition in SQL (e.g. `id = ?` -> `id IN (?)`)
            loc = offense_location(type: type, node: current_node, gda_location: where_condition_gda_loc)
            return unless loc

            corrector.replace(loc, "#{where_column} IN (?)")

            # Replace 2nd arg in db.xquery (e.g. `course[:teacher_id]` -> `courses.map { |course| course[:teacher_id] }`)
            return unless current_node.child_nodes.count == 3

            xquery_arg = current_node.child_nodes[2]
            return if !xquery_arg.send_type? || !xquery_arg.node_parts[0].lvar_type?

            # TODO: check all patterns (course[:teacher_id], course["teacher_id"], course.fetch(:teacher_id), course.fetch("teacher_id"))
            return unless xquery_arg.node_parts[1] == :[]
            return unless xquery_arg.node_parts[2].sym_type?

            corrector.replace(xquery_arg.loc.expression, "#{parent_receiver.source}.map { |#{xquery_arg.node_parts[0].source}| #{xquery_arg.node_parts[0].source}[#{xquery_arg.node_parts[2].source}] }")

            # Replace `.first` -> `.each_with_object({}) { |v, hash| hash[v[:id]] = v }`
            return unless current_node.parent.node_parts.count == 2

            xquery_chained_method = current_node.parent.node_parts[1]
            return if xquery_chained_method != :first && xquery_chained_method != :last

            xquery_chained_method_begin_pos = current_node.loc.end.end_pos + 1
            xquery_chained_method_range = Parser::Source::Range.new(current_node.loc.expression.source_buffer, xquery_chained_method_begin_pos, xquery_chained_method_begin_pos + xquery_chained_method.length)

            corrector.replace(xquery_chained_method_range, "each_with_object({}) { |v, hash| hash[v[:id]] = v }")

            # Split line
            #
            # e.g.
            # Before
            #   teacher = db.xquery("SELECT * FROM `users` WHERE `id` IN (?)", courses.map { |course| course[:teacher_id] }).each_with_object({}) { |v, hash| hash[v[:id]] = v }
            #
            # After
            #   @users_by_id ||= db.xquery("SELECT * FROM `users` WHERE `id` IN (?)", ...).each_with_object({}) { |v, hash| hash[v[:id]] = v }
            #   teacher = @users_by_id[course[:teacher_id]]

            xquery_lvar = current_node.parent&.parent
            return unless xquery_lvar.lvasgn_type?

            first_line_lvar_range = Parser::Source::Range.new(current_node.loc.expression.source_buffer, xquery_lvar.loc.expression.begin_pos, current_node.loc.expression.begin_pos)
            instance_var_name = "@#{gda.table_names[0]}_by_#{where_column.gsub("`", "")}"
            corrector.replace(first_line_lvar_range, "#{instance_var_name} ||= ")

            indent_level = indent_level(current_node)

            second_line_lvar_range = Parser::Source::Range.new(current_node.loc.expression.source_buffer, xquery_lvar.loc.expression.end_pos + 1, xquery_lvar.loc.expression.end_pos + 1)
            corrector.replace(second_line_lvar_range, " " * indent_level + "#{xquery_lvar.node_parts[0]} = #{instance_var_name}[#{xquery_arg.node_parts[0].source}[#{xquery_arg.node_parts[2].source}]]\n")
          end

          # @param node [RuboCop::AST::Node]
          # @return [Integer]
          def indent_level(node)
            node.loc.expression.source_line =~ /^(\s+)/
            return 0 unless $1

            $1.length
          end
        end
      end
    end
  end
end
