# frozen_string_literal: true

GDA::Nodes::Node.class_eval do
  # @!attribute [rw] location
  #   @return [RuboCop::Isucon::GDA::NodeLocation]
  attr_accessor :location
end

GDA::Nodes::Select.class_eval do
  def where_cond_with_cache
    @where_cond_with_cache ||= where_cond_without_cache
  end

  alias_method :where_cond_without_cache, :where_cond
  alias_method :where_cond, :where_cond_with_cache
end

GDA::Nodes::Expr.class_eval do
  def cond_with_cache
    @cond_with_cache ||= cond_without_cache
  end

  alias_method :cond_without_cache, :cond
  alias_method :cond, :cond_with_cache
end

GDA::Nodes::Operation.class_eval do
  def operands_with_cache
    @operands_with_cache ||= operands_without_cache
  end

  alias_method :operands_without_cache, :operands
  alias_method :operands, :operands_with_cache

  def operator_with_cache
    @operator_with_cache ||= operator_without_cache
  end

  alias_method :operator_without_cache, :operator
  alias_method :operator, :operator_with_cache
end
