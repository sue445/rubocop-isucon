# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Helper methods for `db.xquery` in AST
        module Mysql2Methods
          extend NodePattern::Macros

          def_node_search :find_xquery, <<~PATTERN
            (send (send nil? _) {:xquery | :query} (${str dstr} $...) ...)
          PATTERN

          private

          # @param type [Symbol]
          # @param params [Array<RuboCop::AST::Node>]
          # @return [String,nil]
          def xquery_param(type, params)
            case type
            when :str
              params[0]
            when :dstr
              # heredoc
              params.map(&:value).join
            end
          end

          # @param node [RuboCop::AST::Node]
          # @return [Integer,nil]
          # @raise [ArgumentError] `node` is invalid
          def sql_select_location_begin_position(node)
            if node.child_nodes.count >= 2
              # without substitution (e.g. `db.xquery("SELECT * FROM users")`)
              return sql_select_location_begin_position_for_without_substitution(node)
            end

            if node.child_nodes.count == 1
              if node.child_nodes[0].child_nodes.count > 1
                # with substitution (e.g. `rows = db.xquery("SELECT * FROM users")`)
                return sql_select_location_begin_position_for_with_substitution(node)
              end

              # end of method
              return sql_select_location_begin_position_for_end_of_method(node)
            end

            raise ArgumentError, "node.child_nodes is empty"
          end

          # @param node [RuboCop::AST::Node]
          # @return [Integer,nil]
          def sql_select_location_begin_position_for_without_substitution(node)
            query_node = node.child_nodes.find(&:str_type?)
            return nil unless query_node

            query_node.loc.begin.end_pos
          end

          # @param node [RuboCop::AST::Node]
          # @return [Integer,nil]
          def sql_select_location_begin_position_for_with_substitution(node)
            query_node = node.child_nodes[0].child_nodes.find(&:str_type?)
            return nil unless query_node

            query_node.loc.begin.end_pos
          end

          # @param node [RuboCop::AST::Node]
          # @return [Integer,nil]
          def sql_select_location_begin_position_for_end_of_method(node)
            query_node = node.child_nodes[0].child_nodes[0].child_nodes.find(&:str_type?)
            return nil unless query_node

            query_node.loc.begin.end_pos
          end

          # @param dstr_node [RuboCop::AST::DstrNode]
          # @param pattern [Regexp]
          # @return [Integer]
          def text_begin_position_within_heredoc(dstr_node, pattern)
            pattern_str_node = dstr_node.child_nodes.find { |str_node| str_node.value.match?(pattern) }
            return nil unless pattern_str_node

            str_node_begin_pos = pattern_str_node.loc.expression.begin_pos
            pattern_pos = pattern_str_node.value.index(pattern)

            if dstr_node.heredoc?
              heredoc_body = dstr_node.loc.heredoc_body.source
              heredoc_indent_level = indent_level(heredoc_body)
              return str_node_begin_pos + heredoc_indent_level + pattern_pos
            end

            # e.g.
            #   db.xquery(
            #     "SELECT * " \
            #     "FROM users " \
            #     "LIMIT 10"
            #   )
            str_node_begin_pos + pattern_pos
          end

          # @param str [String]
          # @return [Integer]
          # @note https://github.com/rubocop/rubocop/blob/v1.21.0/lib/rubocop/cop/mixin/heredoc.rb#L23-L28
          def indent_level(str)
            indentations = str.lines.
                           map { |line| line[/^\s*/] }.
                           reject { |line| line.end_with?("\n") }
            indentations.empty? ? 0 : indentations.min_by(&:size).size
          end
        end
      end
    end
  end
end
