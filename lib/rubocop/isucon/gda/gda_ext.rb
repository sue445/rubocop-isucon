# frozen_string_literal: true

GDA::Nodes::Node.class_eval do
  # @!attribute [rw] location
  #   @return [RuboCop::Isucon::GDA::NodeLocation]
  attr_accessor :location

  # @return [String]
  def inspect
    # NOTE: Suppress the inclusion of instance variables in `#inspect`
    encoded_object_id = super[/#<#{self.class.name}:0x([0-9a-z]{16})/, 1]
    "#<#{self.class.name}:0x#{encoded_object_id}>"
  end
end

GDA::Nodes::Select.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :distinct_expr
  memorize :expr_list
  memorize :from
  memorize :where_cond
  memorize :group_by
  memorize :having_cond
  memorize :order_by
  memorize :limit_count
  memorize :limit_offset
end

GDA::Nodes::Insert.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :table
  memorize :fields_list
  memorize :values_list
  memorize :select
end

GDA::Nodes::Update.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :table
  memorize :fields_list
  memorize :expr_list
  memorize :cond
end

GDA::Nodes::Join.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :expr
  memorize :use
end

GDA::Nodes::Delete.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :table
  memorize :cond
end

GDA::Nodes::SelectField.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :expr
end

GDA::Nodes::Expr.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :func
  memorize :cond
  memorize :select
  memorize :case_s
  memorize :param_spec
end

GDA::Nodes::From.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :targets
  memorize :joins
end

GDA::Nodes::Target.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :expr
end

GDA::Nodes::Operation.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :operands
end

GDA::Nodes::Function.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :args_list
end

GDA::Nodes::Order.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :expr
end

GDA::Nodes::Unknown.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :expressions
end

GDA::Nodes::Compound.class_eval do
  extend RuboCop::Isucon::MemorizeMethods

  memorize :stmt_list
end
