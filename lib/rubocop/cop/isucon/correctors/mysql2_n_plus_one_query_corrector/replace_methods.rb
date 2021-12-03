# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Correctors
        class Mysql2NPlusOneQueryCorrector
          # replace ast
          module ReplaceMethods
            def replace
              replace_where_condition_in_sql
              replace_xquery_2nd_arg
              replace_chained_method_to_each_with_object
              replace_to_2_lines
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
                # e.g.
                # courses.map { |course| course[:teacher_id] }
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

              corrector.replace(xquery_chained_method_range, generate_each_with_object)
            end

            # @return [String]
            #
            # @example response example
            #   each_with_object({}) { |v, hash| hash[v[:id]] = v }
            def generate_each_with_object
              hash_key =
                case xquery_arg.node_parts[2].type
                when :sym
                  ":#{where_column_without_quote}"
                when :str
                  %("#{where_column_without_quote}")
                end

              "each_with_object({}) { |v, hash| hash[v[#{hash_key}]] = v }"
            end

            # rubocop:disable Layout/LineLength

            # Split line
            #
            # @example Before
            #   teacher = db.xquery("SELECT * FROM `users` WHERE `id` IN (?)", courses.map { |course| course[:teacher_id] }).each_with_object({}) { |v, hash| hash[v[:id]] = v }
            #
            # @example After
            #   @users_by_id ||= db.xquery("SELECT * FROM `users` WHERE `id` IN (?)", ...).each_with_object({}) { |v, hash| hash[v[:id]] = v }
            #   teacher = @users_by_id[course[:teacher_id]]
            def replace_to_2_lines
              # rubocop:enable Layout/LineLength

              replace_to_2_lines_for_1st_line
              replace_to_2_lines_for_2nd_line
            end

            # @return [String]
            def instance_var_name
              "@#{gda.table_names[0]}_by_#{where_column_without_quote}"
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
            #
            # @example response example
            #   teacher = @users_by_id[course[:teacher_id]]
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
end
