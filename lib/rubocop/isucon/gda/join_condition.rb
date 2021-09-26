# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # response of {RuboCop::Isucon::GDA::Client#join_conditions}
      class JoinCondition
        # @!attribute [rw] operator
        #   @return [String]
        attr_accessor :operator

        # @!attribute [rw] operands
        #   @return [Array<RuboCop::Isucon::GDA::JoinOperand>]
        attr_accessor :operands

        # @param operator [String]
        # @param operands [Array<RuboCop::Isucon::GDA::JoinOperand>]
        def initialize(operator: nil, operands: [])
          @operator = operator
          @operands = operands
        end
      end
    end
  end
end
