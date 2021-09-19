# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # Monkey patching to `GDA::Nodes::Node`
      class NodePatcher < ::GDA::Visitors::Visitor
        # @param sql [String]
        def initialize(sql)
          @sql = sql
          @current_pos = 0
          super()
        end

        private

        # @param [GDA::Nodes::Operation]
        def visit_GDA_Nodes_Operation(node) # rubocop:disable Naming/MethodName -- This method is called from `GDA::Visitors::Visitor#visit` c.f. https://github.com/tenderlove/gda/blob/v1.1.0/lib/gda/visitors/visitor.rb#L13-L17
          return super unless node.operator

          pattern = operand_pattern(node)
          return super unless pattern

          node.location = search_location(pattern)

          super
        end

        # @param [GDA::Nodes::Operation]
        # @return [Regexp,nil]
        def operand_pattern(node)
          case node.operands.count
          when 1
            /#{node.operands[0].value}\s*#{node.operator}/
          when 2
            /#{node.operands[0].value}\s*#{node.operator}\s*#{node.operands[1].value}/
          end
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
