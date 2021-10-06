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

          # @param node [RuboCop::AST::Node]
          # @yieldparam type [Symbol] one of `:str`, `:dstr`
          # @yieldparam root_gda [RuboCop::Isucon::GDA::Client]
          def with_xquery(node)
            find_xquery(node) do |type, params|
              sql = xquery_param(type: type, params: params)

              root_gda = RuboCop::Isucon::GDA::Client.new(sql)

              yield type, root_gda
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
          # @return [Integer,nil]
          def begin_position_from_gda_location(type:, node:, gda_location:)
            case type
            when :str
              return begin_position_from_gda_location_for_str(node: node, gda_location: gda_location)
            when :dstr
              return begin_position_from_gda_location_for_dstr(node: node, gda_location: gda_location)
            end

            nil
          end

          # @param node [RuboCop::AST::Node]
          # @param gda_location [RuboCop::Isucon::GDA::NodeLocation]
          # @return [Integer,nil]
          def begin_position_from_gda_location_for_str(node:, gda_location:)
            str_node = node.child_nodes[1]
            return nil if !str_node || !str_node.str_type?

            str_node.loc.begin.end_pos + gda_location.begin_pos
          end

          # @param node [RuboCop::AST::Node]
          # @param gda_location [RuboCop::Isucon::GDA::NodeLocation]
          # @return [Integer,nil]
          def begin_position_from_gda_location_for_dstr(node:, gda_location:)
            dstr_node = node.child_nodes[1]
            return nil if !dstr_node || !dstr_node.dstr_type?

            str_node = find_str_node_from_gda_location(dstr_node: dstr_node, gda_location: gda_location)
            index = str_node.value.index(gda_location.body)
            return nil unless index

            str_node_begin_pos(str_node) + index + heredoc_indent_level(node)
          end

          # @param str_node [RuboCop::AST::StrNode]
          # @return [Integer]
          def str_node_begin_pos(str_node)
            begin_pos = str_node.loc.expression.begin_pos

            # e.g.
            #   db.xquery(
            #     "SELECT * " \
            #     "FROM users " \
            #     "LIMIT 10"
            #   )
            return begin_pos + 1 if str_node.loc.expression.source_buffer.source[begin_pos] == '"'

            begin_pos
          end

          # @param dstr_node [RuboCop::AST::DstrNode]
          # @param gda_location [RuboCop::Isucon::GDA::NodeLocation]
          # @return [RuboCop::AST::StrNode,nil]
          def find_str_node_from_gda_location(dstr_node:, gda_location:)
            return nil unless dstr_node

            begin_pos = 0
            dstr_node.child_nodes.each do |str_node|
              return str_node if begin_pos <= gda_location.begin_pos && gda_location.begin_pos < begin_pos + str_node.value.length

              begin_pos += str_node.value.length
            end
            nil
          end

          # @param node [RuboCop::AST::Node]
          # @return [Integer]
          def heredoc_indent_level(node)
            dstr_node = node.child_nodes[1]
            return 0 if !dstr_node || !dstr_node.dstr_type?

            heredoc_indent_type = heredoc_indent_type(node)
            return 0 unless heredoc_indent_type == "~"

            heredoc_body = dstr_node.loc.heredoc_body.source
            indent_level(heredoc_body)
          end

          # @param str [String]
          # @return [Integer]
          # @see https://github.com/rubocop/rubocop/blob/v1.21.0/lib/rubocop/cop/mixin/heredoc.rb#L23-L28
          def indent_level(str)
            indentations = str.lines.
                           map { |line| line[/^\s*/] }.
                           reject { |line| line.end_with?("\n") }
            indentations.empty? ? 0 : indentations.min_by(&:size).size
          end

          # Returns '~', '-' or nil
          #
          # @param node [RuboCop::AST::Node]
          # @return [String,nil] '~', '-' or `nil`
          # @see https://github.com/rubocop/rubocop/blob/v1.21.0/lib/rubocop/cop/layout/heredoc_indentation.rb#L146-L149
          def heredoc_indent_type(node)
            node.source[/<<([~-])/, 1]
          end
        end
      end
    end
  end
end
