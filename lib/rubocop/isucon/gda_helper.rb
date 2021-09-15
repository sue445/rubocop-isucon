# frozen_string_literal: true

module RuboCop
  module Isucon
    # Wrapper for `GDA`
    #
    # @see https://github.com/tenderlove/gda
    # @see https://gitlab.gnome.org/GNOME/libgda
    class GdaHelper
      PRACEHOLDER = "'__PRACEHOLDER__'"

      attr_reader :ast

      # @param sql [String]
      # @param ast [GDA::Nodes::Select]
      def initialize(sql, ast = nil)
        @sql = sql
        @ast = ast || statement.ast
      end

      # @return [Array<String>]
      def table_names
        ast.from.targets.map(&:table_name)
      end

      # @return [Array<RuboCop::Isucon::GdaHelper::WhereCondition>]
      def where_clause
        ast.where_cond.to_a.
          select { |node| node.instance_of?(GDA::Nodes::Operation) && node.operator }.
          map do |node|
            WhereCondition.new(
              operator: node.operator,
              operands: node.operands.map { |operand| operand.value.gsub(/^.+\./, "") },
            )
          end
      end

      # @return [Hash]
      def serialize_statement
        JSON.parse(statement.serialize)
      end

      # @yieldparam gda [RuboCop::Isucon::GdaHelper]
      def walk_within_subquery(&block)
        ast.from.targets.each do |target|
          next unless target.expr.select

          gda = GdaHelper.new(nil, target.expr.select)
          block.call(gda)
          gda.walk_within_subquery(&block)
        end
      end

      # @param sql [String]
      # @return [String]
      def self.normalize_sql(sql)
        sql.gsub("`", "").gsub("?", PRACEHOLDER)
      end

      private

      # @return [GDA::SQL::Statement]
      def statement
        @statement ||= GDA::SQL::Parser.new.parse(self.class.normalize_sql(@sql))
      end
    end
  end
end
