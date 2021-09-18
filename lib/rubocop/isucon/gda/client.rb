# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # Wrapper for `GDA`
      #
      # @see https://github.com/tenderlove/gda
      # @see https://gitlab.gnome.org/GNOME/libgda
      class Client
        # @return [GDA::Nodes::Select]
        attr_reader :ast

        # @param sql [String,nil]
        # @param ast [GDA::Nodes::Select]
        # @note if `sql` is `nil`, `ast` is required
        def initialize(sql, ast: nil)
          @sql = sql
          @ast = ast || statement.ast
        end

        # @return [Array<String>]
        def table_names
          ast.from.targets.map(&:table_name)
        end

        # @return [Array<RuboCop::Isucon::GDA::WhereCondition>]
        def where_clause
          ast.where_cond.to_a.
            select { |node| node.instance_of?(::GDA::Nodes::Operation) && node.operator }.
            map do |node|
            WhereCondition.new(
              operator: node.operator,
              operands: node.operands.map { |operand| operand.value.gsub(/^.+\./, "") },
            )
          end
        end

        # @return [Hash,nil]
        def serialize_statement
          return nil unless @sql

          JSON.parse(statement.serialize)
        end

        # @yieldparam gda [RuboCop::Isucon::GDA::Client]
        def visit_subquery_recursive(&block)
          ast.from.targets.each do |target|
            next unless target.expr.select

            gda = Client.new(nil, ast: target.expr.select)
            block.call(gda)
            gda.visit_subquery_recursive(&block)
          end
        end

        # @yieldparam gda [RuboCop::Isucon::GDA::Client]
        def visit_all(&block)
          block.call(self)
          visit_subquery_recursive(&block)
        end

        # @param sql [String]
        # @return [String]
        def self.normalize_sql(sql)
          sql.gsub("`", " ").gsub("?", PRACEHOLDER)
        end

        private

        # @return [GDA::SQL::Statement]
        def statement
          return @statement if @statement

          raise "@sql is required" unless @sql

          @statement = ::GDA::SQL::Parser.new.parse(self.class.normalize_sql(@sql))
        end
      end
    end
  end
end
