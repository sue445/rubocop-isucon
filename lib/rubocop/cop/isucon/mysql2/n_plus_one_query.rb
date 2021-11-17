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
        class NPlusOneQuery < Base # rubocop:disable Metrics/ClassLength
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

            replace_where_condition_in_sql(
              corrector: corrector, current_node: current_node, type: type,
              where_column: where_column, where_condition_gda_loc: where_condition_gda_loc
            )

            return unless current_node.child_nodes.count == 3

            xquery_arg = current_node.child_nodes[2]
            return if !xquery_arg.send_type? || !xquery_arg.node_parts[0].lvar_type?

            # TODO: check all patterns
            # e.g. course[:teacher_id], course["teacher_id"], course.fetch(:teacher_id), course.fetch("teacher_id")
            return unless xquery_arg.node_parts[1] == :[]
            return unless xquery_arg.node_parts[2].sym_type?

            replace_xquery_2nd_arg(
              corrector: corrector, xquery_arg: xquery_arg,
              parent_receiver: parent_receiver
            )

            return unless current_node.parent&.node_parts&.count == 2

            replace_chained_method_to_each_with_object(corrector: corrector, current_node: current_node)

            replace_to_2_lines(corrector: corrector, current_node: current_node, gda: gda,
                               where_column: where_column, xquery_arg: xquery_arg)
          end

          # Replace where condition in SQL (e.g. `id = ?` -> `id IN (?)`)
          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param where_column [String]
          # @param where_condition_gda_loc [RuboCop::Isucon::GDA::NodeLocation]
          def replace_where_condition_in_sql(corrector:, current_node:, type:, where_column:, where_condition_gda_loc:)
            loc = offense_location(type: type, node: current_node, gda_location: where_condition_gda_loc)
            return unless loc

            corrector.replace(loc, "#{where_column} IN (?)")
          end

          # Replace 2nd arg in db.xquery (e.g. `course[:teacher_id]` -> `courses.map { |course| course[:teacher_id] }`)
          # @param corrector [RuboCop::Cop::Corrector]
          # @param xquery_arg [RuboCop::AST::Node]
          # @param parent_receiver [RuboCop::AST::Node]
          def replace_xquery_2nd_arg(corrector:, xquery_arg:, parent_receiver:)
            object_source = xquery_arg.node_parts[0].source
            symbol_source = xquery_arg.node_parts[2].source

            corrector.replace(
              xquery_arg.loc.expression,
              "#{parent_receiver.source}.map { |#{object_source}| #{object_source}[#{symbol_source}] }",
            )
          end

          # Replace `.first` -> `.each_with_object({}) { |v, hash| hash[v[:id]] = v }`
          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          def replace_chained_method_to_each_with_object(corrector:, current_node:)
            xquery_chained_method = current_node.parent.node_parts[1]
            return if xquery_chained_method != :first && xquery_chained_method != :last

            xquery_chained_method_begin_pos = current_node.loc.end.end_pos + 1
            xquery_chained_method_range =
              Parser::Source::Range.new(current_node.loc.expression.source_buffer,
                                        xquery_chained_method_begin_pos,
                                        xquery_chained_method_begin_pos + xquery_chained_method.length)

            corrector.replace(xquery_chained_method_range, "each_with_object({}) { |v, hash| hash[v[:id]] = v }")
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param where_column [String]
          # @param xquery_arg [RuboCop::AST::Node]
          def replace_to_2_lines(corrector:, current_node:, gda:, where_column:, xquery_arg:) # rubocop:disable Metrics/MethodLength
            # rubocop:disable Layout/LineLength
            #
            # Split line
            # e.g.
            # Before
            #   teacher = db.xquery("SELECT * FROM `users` WHERE `id` IN (?)", courses.map { |course| course[:teacher_id] }).each_with_object({}) { |v, hash| hash[v[:id]] = v }
            #
            # After
            #   @users_by_id ||= db.xquery("SELECT * FROM `users` WHERE `id` IN (?)", ...).each_with_object({}) { |v, hash| hash[v[:id]] = v }
            #   teacher = @users_by_id[course[:teacher_id]]
            #
            # rubocop:enable Layout/LineLength

            xquery_lvar = current_node.parent&.parent
            return unless xquery_lvar.lvasgn_type?

            instance_var_name = "@#{gda.table_names[0]}_by_#{where_column.delete('`')}"

            replace_to_2_lines_for_1st_line(
              corrector: corrector, current_node: current_node,
              xquery_lvar: xquery_lvar, instance_var_name: instance_var_name
            )

            replace_to_2_lines_for_2nd_line(
              corrector: corrector, current_node: current_node, xquery_arg: xquery_arg,
              xquery_lvar: xquery_lvar, instance_var_name: instance_var_name
            )
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          # @param xquery_lvar [RuboCop::AST::Node]
          def replace_to_2_lines_for_1st_line(corrector:, current_node:, xquery_lvar:, instance_var_name:)
            range =
              Parser::Source::Range.new(current_node.loc.expression.source_buffer,
                                        xquery_lvar.loc.expression.begin_pos, current_node.loc.expression.begin_pos)

            corrector.replace(range, "#{instance_var_name} ||= ")
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          # @param xquery_arg [RuboCop::AST::Node]
          # @param xquery_lvar [RuboCop::AST::Node]
          # @param instance_var_name [String]
          def replace_to_2_lines_for_2nd_line(corrector:, current_node:, xquery_arg:, xquery_lvar:,
                                              instance_var_name:)
            indent_level = indent_level(current_node)

            pos = xquery_lvar.loc.expression.end_pos + 1
            range = Parser::Source::Range.new(current_node.loc.expression.source_buffer, pos, pos)

            second_line =
              generate_second_line(xquery_arg: xquery_arg, xquery_lvar: xquery_lvar, instance_var_name: instance_var_name)

            corrector.replace(range, (" " * indent_level) + second_line)
          end

          # @param xquery_arg [RuboCop::AST::Node]
          # @param xquery_lvar [RuboCop::AST::Node]
          # @param instance_var_name [String]
          def generate_second_line(xquery_arg:, xquery_lvar:, instance_var_name:)
            object_source = xquery_arg.node_parts[0].source
            symbol_source = xquery_arg.node_parts[2].source
            "#{xquery_lvar.node_parts[0]} = #{instance_var_name}[#{object_source}[#{symbol_source}]]\n"
          end

          # @param node [RuboCop::AST::Node]
          # @return [Integer]
          def indent_level(node)
            node.loc.expression.source_line =~ /^(\s+)/
            return 0 unless Regexp.last_match(1)

            Regexp.last_match(1).length
          end
        end
      end
    end
  end
end
