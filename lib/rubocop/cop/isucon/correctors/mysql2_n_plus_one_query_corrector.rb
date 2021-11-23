# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Correctors
        # rubocop:disable Layout/LineLength

        # Corrector for {RuboCop::Cop::Isucon::Mysql2::NPlusOneQuery}
        #
        # @example Before
        #   courses.map do |course|
        #     teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ?', course[:teacher_id]).first
        #   end
        #
        # @example After
        #   courses.map do |course|
        #     @users_by_id ||= db.xquery('SELECT * FROM `users` WHERE `id` IN (?)', courses.map { |course| course[:teacher_id] }).each_with_object({}) { |v, hash| hash[v[:id]] = v }
        #     teacher = @users_by_id[course[:teacher_id]]
        #   end
        class Mysql2NPlusOneQueryCorrector # rubocop:disable Metrics/ClassLength
          # rubocop:enable Layout/LineLength

          include Mixin::Mysql2Methods

          # @return [RuboCop::Cop::Corrector]
          attr_reader :corrector

          # @return [RuboCop::AST::Node]
          attr_reader :current_node

          # @return [RuboCop::AST::Node]
          attr_reader :parent_node

          # @return [Symbol]
          attr_reader :type

          # @return [RuboCop::Isucon::GDA::Client]
          attr_reader :gda

          # @return [RuboCop::Isucon::DatabaseConnection]
          attr_reader :connection

          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          # @param parent_node [RuboCop::AST::Node]
          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param connection [RuboCop::Isucon::DatabaseConnection]
          def initialize(corrector:, current_node:, parent_node:, type:, gda:, connection:) # rubocop:disable Metrics/ParameterLists
            @corrector = corrector
            @current_node = current_node
            @parent_node = parent_node
            @type = type
            @gda = gda
            @connection = connection
          end

          def correct
            return unless correctable?

            replace_where_condition_in_sql
            replace_xquery_2nd_arg
            replace_chained_method_to_each_with_object
            replace_to_2_lines
          end

          private

          # @return [Boolean]
          def correctable?
            if !correctable_gda? || !correctable_xquery_arg? || !parent_receiver.lvar_type? ||
               current_node.child_nodes.count != 3 || !xquery_lvar.lvasgn_type?

              return false
            end

            return false unless %i[first last].include?(xquery_chained_method)

            true
          end

          # @return [Boolean]
          def correctable_gda?
            gda&.select_query? && gda.table_names.count == 1 && gda.where_nodes.count == 1
          end

          # @return [Boolean]
          def correctable_xquery_arg? # rubocop:disable Metrics/AbcSize
            return false if !xquery_arg&.send_type? || xquery_arg.node_parts.count != 3 || !xquery_arg.node_parts[0].lvar_type?

            # TODO: check all patterns
            # e.g. course[:teacher_id], course["teacher_id"], course.fetch(:teacher_id), course.fetch("teacher_id")
            return false unless xquery_arg.node_parts[1] == :[]
            return false unless xquery_arg.node_parts[2].sym_type?

            true
          end

          # @return [RuboCop::AST::Node,nil]
          def parent_receiver
            parent_node.child_nodes&.first&.receiver
          end

          # @return [RuboCop::Isucon::GDA::NodeLocation]
          def where_condition_gda_loc
            gda.where_nodes.first.location
          end

          # @return [String,nil]
          def where_column
            matched = where_condition_gda_loc&.body&.match(/([^\s]+)\s*=\s*\?/)

            return nil unless matched

            matched[1]
          end

          # @return [RuboCop::AST::Node]
          def xquery_arg
            current_node.child_nodes[2]
          end

          # Replace where condition in SQL (e.g. `id = ?` -> `id IN (?)`)
          def replace_where_condition_in_sql
            loc = offense_location(type: type, node: current_node, gda_location: where_condition_gda_loc)
            return unless loc

            corrector.replace(loc, "#{where_column} IN (?)")
          end

          # Replace 2nd arg in db.xquery (e.g. `course[:teacher_id]` -> `courses.map { |course| course[:teacher_id] }`)
          def replace_xquery_2nd_arg
            object_source = xquery_arg.node_parts[0].source
            symbol_source = xquery_arg.node_parts[2].source

            corrector.replace(
              xquery_arg.loc.expression,
              "#{parent_receiver.source}.map { |#{object_source}| #{object_source}[#{symbol_source}] }",
            )
          end

          # Replace `.first` -> `.each_with_object({}) { |v, hash| hash[v[:id]] = v }`
          def replace_chained_method_to_each_with_object
            xquery_chained_method_begin_pos = current_node.loc.end.end_pos + 1
            xquery_chained_method_range =
              Parser::Source::Range.new(current_node.loc.expression.source_buffer,
                                        xquery_chained_method_begin_pos,
                                        xquery_chained_method_begin_pos + xquery_chained_method.length)

            corrector.replace(xquery_chained_method_range, "each_with_object({}) { |v, hash| hash[v[:id]] = v }")
          end

          # @return [RuboCop::AST::Node]
          def xquery_chained_method
            current_node.parent.node_parts[1]
          end

          def replace_to_2_lines
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

            replace_to_2_lines_for_1st_line
            replace_to_2_lines_for_2nd_line
          end

          # @return [String]
          def instance_var_name
            "@#{gda.table_names[0]}_by_#{where_column.delete('`')}"
          end

          # @return [RuboCop::AST::Node,nil]
          def xquery_lvar
            current_node.parent&.parent
          end

          def replace_to_2_lines_for_1st_line
            range =
              Parser::Source::Range.new(current_node.loc.expression.source_buffer,
                                        xquery_lvar.loc.expression.begin_pos, current_node.loc.expression.begin_pos)

            corrector.replace(range, "#{instance_var_name} ||= ")
          end

          def replace_to_2_lines_for_2nd_line
            indent_level = indent_level(current_node)

            pos = xquery_lvar.loc.expression.end_pos + 1
            range = Parser::Source::Range.new(current_node.loc.expression.source_buffer, pos, pos)

            corrector.replace(range, "#{' ' * indent_level}#{generate_second_line}")
          end

          # @return [String]
          def generate_second_line
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
