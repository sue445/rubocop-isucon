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
end
