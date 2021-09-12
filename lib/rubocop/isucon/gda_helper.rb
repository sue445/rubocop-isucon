# frozen_string_literal: true

module RuboCop
  module Isucon
    # Wrapper for #{GDA}
    class GdaHelper
      PRACEHOLDER = "'__PRACEHOLDER__'"

      # @param sql [String]
      def initialize(sql)
        @sql = sql
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
              operands: node.operands.map(&:value),
            )
          end
      end

      # @param sql [String]
      # @return [String]
      def self.normalize_sql(sql)
        sql.gsub("`", "").gsub("?", PRACEHOLDER)
      end

      private

      # @return [GDA::Nodes::Select]
      def ast
        @ast ||= GDA::SQL::Parser.new.parse(self.class.normalize_sql(@sql)).ast
      end
    end
  end
end