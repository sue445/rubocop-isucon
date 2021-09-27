# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # response of {RuboCop::Isucon::GDA::Client#join_conditions}
      class JoinOperand
        # @!attribute [rw] table_name
        #   @return [String]
        attr_accessor :table_name

        # @!attribute [rw] column_name
        #   @return [String]
        attr_accessor :column_name

        # @!attribute [rw] as
        #   @return [String]
        attr_accessor :as

        # @!attribute [rw] node
        #   @return [GDA::Nodes::Expr]
        attr_accessor :node

        # @param table_name [String]
        # @param column_name [String]
        # @param as [String]
        # @param node [GDA::Nodes::Expr]
        def initialize(table_name: nil, column_name: nil, as: nil, node: nil) # rubocop:disable Naming/MethodParameterName
          @table_name = table_name
          @column_name = column_name
          @as = as
          @node = node
        end

        # @param other [RuboCop::Isucon::GDA::JoinOperand]
        # @return [Boolean]
        def ==(other)
          other.is_a?(JoinOperand) &&
            table_name == other.table_name &&
            column_name == other.column_name &&
            as == other.as
        end
      end
    end
  end
end
