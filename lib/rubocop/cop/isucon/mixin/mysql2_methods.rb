# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Helper methods for `db.xquery` in AST
        module Mysql2Methods # rubocop:disable Metrics/ModuleLength
          extend NodePattern::Macros

          def_node_search :find_xquery, <<~PATTERN
            (send (send nil? _) {:xquery | :query} (${str dstr} $...) ...)
          PATTERN

          private

          # @param type [Symbol]
          # @param params [Array<RuboCop::AST::Node>]
          # @return [String,nil]
          def xquery_param(type:, params:)
            case type
            when :str
              params[0]
            when :dstr
              # heredoc
              params.map(&:value).join
            end
          end

          # @param type [Symbol] one of `:str`, `:dstr`
          # @param node [RuboCop::AST::Node]
          # @param gda_location [RuboCop::Isucon::GDA::NodeLocation]
          # @return [Parser::Source::Range,nil]
          def offense_location(type:, node:, gda_location:)
            return nil unless gda_location

            begin_pos = begin_position_from_gda_location(type: type, node: node, gda_location: gda_location)
            return nil unless begin_pos

            end_pos = begin_pos + gda_location.length
            Parser::Source::Range.new(node.loc.expression.source_buffer, begin_pos, end_pos)
          end

          # @param type [Symbol] one of `:str`, `:dstr`
          # @param node [RuboCop::AST::Node]
          # @param gda_location [RuboCop::Isucon::GDA::NodeLocation]
          # @return [Integer,nil]
          def begin_position_from_gda_location(type:, node:, gda_location:)
            case type
            when :str
              str_node = node.child_nodes[1]
              return nil if !str_node || !str_node.str_type?

              return str_node.loc.begin.end_pos + gda_location.begin_pos
            when :dstr
              dstr_node = node.child_nodes[1]
              return nil if !dstr_node || !dstr_node.dstr_type?

              heredoc_indent_type = heredoc_indent_type(node)
              heredoc_indent_level =
                if heredoc_indent_type == "~"
                  heredoc_body = dstr_node.loc.heredoc_body.source
                  indent_level(heredoc_body)
                else
                  0
                end

              begin_pos = 0
              node.child_nodes[1].child_nodes.each do |str_node|
                if begin_pos <= gda_location.begin_pos && gda_location.begin_pos < begin_pos + str_node.value.length
                  index = str_node.value.index(gda_location.body)
                  return nil unless index

                  result = str_node.loc.expression.begin_pos + index
                  result += 1 if str_node.loc.expression.source_buffer.source[str_node.loc.expression.begin_pos] == '"'
                  return result + heredoc_indent_level
                end
                begin_pos += str_node.value.length
              end
            end

            nil
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
          # @return [Integer,nil]
          def text_begin_position_within_heredoc(dstr_node:, pattern:)
            pattern_str_node = dstr_node.child_nodes.find { |str_node| str_node.value.match?(pattern) }
            return nil unless pattern_str_node

            str_node_begin_pos = node_expression_begin_pos(pattern_str_node)
            pattern_pos = search_in_node(node: pattern_str_node, pattern: pattern)

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

          # @param node [RuboCop::AST::DstrNode]
          # @param pattern [Regexp]
          # @return [Integer]
          def search_in_node(node:, pattern:)
            node.value.index(pattern)
          end

          # @param node [RuboCop::AST::DstrNode]
          # @return [Integer]
          def node_expression_begin_pos(node)
            node.loc.expression.begin_pos
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

          # Returns '~', '-' or nil
          #
          # @param node [RuboCop::AST::Node]
          # @return [String,nil] '~', '-' or nil
          def heredoc_indent_type(node)
            # c.f. https://github.com/rubocop/rubocop/blob/v1.21.0/lib/rubocop/cop/layout/heredoc_indentation.rb#L146-L149
            node.source[/<<([~-])/, 1]
          end

          # @param table_names [Array<String>]
          # @param column_name [String]
          # @return [String,nil]
          def find_table_name_from_column_name(table_names:, column_name:)
            table_names.each do |table_name|
              column_names = connection.column_names(table_name)
              return table_name if column_names.include?(column_name)
            end
            nil
          end
        end
      end
    end
  end
end
