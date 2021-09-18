# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # response of {RuboCop::Isucon::GdaHelper#where_clause}
      class WhereCondition
        # @!attribute [rw] operator
        #   @return [String]
        attr_accessor :operator

        # @!attribute [rw] operands
        #   @return [Array<String>]
        attr_accessor :operands

        # @param operator [String]
        # @param operands [Array<String>]
        def initialize(operator: nil, operands: [])
          @operator = operator
          @operands = operands
        end

        # @return [String,nil]
        def column_operand
          return operands[0] if operands.count == 1

          operand0_type = operand_type(operands[0])
          operand1_type = operand_type(operands[1])

          return operands[0] if operand0_type == :column || operand1_type == :value
          return operands[1] if operand1_type == :column || operand0_type == :value

          nil
        end

        # @return [String,nil]
        def value_operand
          return nil if operands.count == 1

          operand0_type = operand_type(operands[0])
          operand1_type = operand_type(operands[1])

          return operands[0] if operand0_type == :value || operand1_type == :column
          return operands[1] if operand1_type == :value || operand0_type == :column

          nil
        end

        private

        # @param operand [String]
        # @return [Symbol]
        def operand_type(operand)
          case operand
          when RuboCop::Isucon::GdaHelper::PRACEHOLDER, /^'.+'$/, /^[0-9.]+$/
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
