# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # Monkey patching to `GDA::Nodes::Node`
      class NodePatcher < ::GDA::Visitors::Visitor
        # @param sql [String]
        def initialize(sql)
          @sql = sql
          @normalized_sql = RuboCop::Isucon::GDA.normalize_sql(sql)
          @current_operation_pos = 0
          @current_expr_pos = 0
          super()
        end

        private

        # @param node [GDA::Nodes::Operation]
        def visit_GDA_Nodes_Operation(node) # rubocop:disable Naming/MethodName -- This method is called from `GDA::Visitors::Visitor#visit` c.f. https://github.com/tenderlove/gda/blob/v1.1.0/lib/gda/visitors/visitor.rb#L13-L17
          return super unless node.operator

          pattern = operand_pattern(node)
          return super unless pattern

          node.location = search_operation_location(pattern)

          super
        end

        # @param node [GDA::Nodes::Operation]
        # @return [Regexp,nil]
        def operand_pattern(node)
          case node.operands.count
          when 1
            /#{Regexp.escape(node.operands[0].value)}\s*#{Regexp.escape(node.operator)}/
          when 2
            /#{Regexp.escape(node.operands[0].value)}\s*#{Regexp.escape(node.operator)}\s*#{Regexp.escape(node.operands[1].value)}/
          end
        end

        # @param pattern [Regexp]
        # @return [RuboCop::Isucon::GDA::NodeLocation,nil]
        def search_operation_location(pattern)
          result = search_location(pattern, @current_operation_pos)
          return nil unless result

          @current_operation_pos = result[:current_pos] if result[:current_pos]
          result[:location]
        end

        # @param pattern [Regexp]
        # @param current_pos [Integer]
        # @return [Hash]
        def search_location(pattern, current_pos)
          begin_pos = @normalized_sql.index(pattern, current_pos)

          return nil unless Regexp.last_match

          length = Regexp.last_match[0].length
          end_pos = begin_pos + length

          begin_pos -= 1 if @sql[begin_pos - 1] == "`"
          end_pos += 1 if @sql[end_pos] == "`"

          {
            location: NodeLocation.new(begin_pos: begin_pos, end_pos: end_pos, body: @sql[begin_pos...end_pos]),
            current_pos: end_pos,
          }
        end

        # @param node [GDA::Nodes::Expr]
        def visit_GDA_Nodes_Expr(node) # rubocop:disable Naming/MethodName -- This method is called from `GDA::Visitors::Visitor#visit` c.f. https://github.com/tenderlove/gda/blob/v1.1.0/lib/gda/visitors/visitor.rb#L13-L17
          return super unless node.value

          escaped_value = Regexp.escape(node.value).gsub("\\.", "\\s*\\.\\s*")
          node.location = search_expr_location(/(?<=[\s,])#{escaped_value}(?=[\s,])/)
          super
        end

        # @param pattern [Regexp]
        # @return [RuboCop::Isucon::GDA::NodeLocation,nil]
        def search_expr_location(pattern)
          result = search_location(pattern, @current_expr_pos)
          return nil unless result

          @current_expr_pos = result[:current_pos] if result[:current_pos]
          result[:location]
        end
      end
    end
  end
end
