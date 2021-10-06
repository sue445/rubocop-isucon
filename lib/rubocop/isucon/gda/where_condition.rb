# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # response of {RuboCop::Isucon::GDA::Client#where_conditions}
      class WhereCondition
        # @!attribute [rw] operator
        #   @return [String]
        attr_accessor :operator

        # @!attribute [rw] operands
        #   @return [Array<RuboCop::Isucon::GDA::WhereOperand>]
        attr_accessor :operands

        # @param operator [String]
        # @param operands [Array<RuboCop::Isucon::GDA::WhereOperand>]
        def initialize(operator: nil, operands: [])
          @operator = operator
          @operands = operands
        end

        # @return [String,nil]
        def column_operand
          operand0_value = operands[0].value

          return operand0_value if operands.count == 1

          operand1_value = operands[1].value

          operand0_type = operand_type(operand0_value)
          operand1_type = operand_type(operand1_value)

          return operand0_value if operand0_type == :column || operand1_type == :value
          return operand1_value if operand1_type == :column || operand0_type == :value

          nil
        end

        # @return [String,nil]
        def value_operand
          return nil if operands.count == 1

          operand0_value = operands[0].value
          operand1_value = operands[1].value

          operand0_type = operand_type(operand0_value)
          operand1_type = operand_type(operand1_value)

          return operand0_value if operand0_type == :value || operand1_type == :column
          return operand1_value if operand1_type == :value || operand0_type == :column

          nil
        end

        private

        # @param operand [String]
        # @return [Symbol]
        def operand_type(operand)
          case operand
          when PRACEHOLDER, /^'.+'$/, /^[0-9.]+$/
            :value
          when /^[A-Za-z0-9_$]*$/
            :column
          else
            :unknown
          end
        end
      end
    end
  end
end
