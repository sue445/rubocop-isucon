# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # Monkey patching to `GDA::Nodes::Node`
      class NodePatcher < ::GDA::Visitors::Visitor
        # @param node [GDA::Nodes::Node]
        # @param sql [String]
        def accept(node, sql)
          @sql = sql
          @current_pos = 0
          super(node)
        end

        private

        def visit_GDA_Nodes_Operation(node) # rubocop:disable Naming/MethodName,Metrics/MethodLength
          return super unless node.operator

          pattern =
            case node.operands.count
            when 1
              /#{node.operands[0].value}\s*#{node.operator}/
            when 2
              /#{node.operands[0].value}\s*#{node.operator}\s*#{node.operands[1].value}/
            else
              return super
            end

          node.location = search_location(pattern)

          super
        end

        # @param [Regexp] pattern
        # @return [RuboCop::Isucon::GDA::NodeLocation]
        def search_location(pattern)
          begin_pos = @sql.index(pattern, @current_pos)
          length = Regexp.last_match[0].length
          end_pos = begin_pos + length
          @current_pos = end_pos

          NodeLocation.new(begin_pos: begin_pos, end_pos: end_pos, body: Regexp.last_match[0])
        end
      end
    end
  end
end
