# frozen_string_literal: true

# response of {RuboCop::Isucon::GdaHelper#where_clause}
class RuboCop::Isucon::GdaHelper::WhereCondition # rubocop:disable Style/ClassAndModuleChildren
  # @!attribute [rw] operator
  #   @return [String]
  attr_accessor :operator

  # @!attribute [rw] operands
  #   @return [Array<String>]
  attr_accessor :operands

  # @param operator [String]
  # @param operands [Array<String>]
  def initialize(operator: nil, operands: nil)
    @operator = operator
    @operands = operands
  end

  # @return [String,nil]
  def column_operand
    return operands[0] if operands.count == 1

    return operands[0] if operand_type(operands[0]) == :column
    return operands[1] if operand_type(operands[1]) == :column
    return operands[0] if operand_type(operands[1]) == :value
    return operands[1] if operand_type(operands[0]) == :value

    nil
  end

  # @return [String,nil]
  def value_operand
    return nil if operands.count == 1

    return operands[0] if operand_type(operands[0]) == :value
    return operands[1] if operand_type(operands[1]) == :value
    return operands[0] if operand_type(operands[1]) == :column
    return operands[1] if operand_type(operands[0]) == :column

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
