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

      # @return [GDA::Nodes::Select]
      def ast
        @ast ||= statement.ast
      end
    end
  end
end
