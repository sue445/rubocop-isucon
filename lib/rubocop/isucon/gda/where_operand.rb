# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # response of {RuboCop::Isucon::GDA::Client#where_conditions}
      class WhereOperand
        # @!attribute [rw] value
        #   @return [String]
        attr_accessor :value

        # @!attribute [rw] node
        #   @return [GDA::Nodes::Expr]
        attr_accessor :node

        # @param value [String]
        # @param node [GDA::Nodes::Expr]
        def initialize(value: nil, node: nil)
          @value = value
          @node = node
        end

        # @param other [RuboCop::Isucon::GDA::WhereOperand]
        # @return [Boolean]
        def ==(other)
          other.is_a?(WhereOperand) &&
            value == other.value
        end
      end
    end
  end
end
