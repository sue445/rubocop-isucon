# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # Client for `GDA`
      class Client
        # @return [GDA::Nodes::Select]
        attr_reader :ast

        # @return [String]
        attr_reader :sql

        # @param sql [String,nil]
        # @param ast [GDA::Nodes::Select]
        # @note if `sql` is `nil`, `ast` is required
        def initialize(sql, ast: nil)
          @sql = sql

          if ast
            # called from subquery AST
            @ast = ast
          else
            # called from root AST
            @ast = statement.ast
            RuboCop::Isucon::GDA::NodePatcher.new(sql).accept(@ast)
          end
        end

        # @return [Array<String>]
        def table_names
          @table_names ||= ast.from.targets.map(&:table_name).compact.uniq
        end

        # @return [Array<RuboCop::Isucon::GDA::WhereCondition>]
        def where_conditions
          where_nodes.
            map do |node|
              where_operands = node.operands.map do |operand|
                create_where_operand(operand)
              end

              WhereCondition.new(
                operator: node.operator,
                operands: where_operands,
              )
            end
        end

        # @return [Array<RuboCop::Isucon::GDA::JoinCondition>]
        def join_conditions
          return [] unless ast.respond_to?(:from)

          ast.from.joins.map do |node|
            join_operands = node.expr.cond.operands.map do |operand|
              create_join_operand(operand)
            end

            JoinCondition.new(
              operator: node.expr.cond.operator,
              operands: join_operands,
            )
          end
        end

        # @return [Array<GDA::Nodes::Operation>]
        def where_nodes
          ast.where_cond.to_a.
            select { |node| node.instance_of?(::GDA::Nodes::Operation) && node.operator }
        end

        # @return [Hash,nil]
        def serialize_statement
          return nil unless @sql

          JSON.parse(statement.serialize)
        end

        # @yieldparam gda [RuboCop::Isucon::GDA::Client]
        def visit_subquery_recursive(&block)
          return unless ast.respond_to?(:from)

          ast.from.targets.each do |target|
            next unless target.expr.select

            gda = Client.new(nil, ast: target.expr.select)
            yield(gda)
            gda.visit_subquery_recursive(&block)
          end
        end

        # @yieldparam gda [RuboCop::Isucon::GDA::Client]
        def visit_all(&block)
          yield(self)
          visit_subquery_recursive(&block)
        end

        # @return [Boolean]
        def select_query?
          ast.is_a?(::GDA::Nodes::Select)
        end

        # Whether `SELECT` clause contains aggregate functions (`COUNT`, `MAX`, `MIN`, `SUM` or `AVG`)
        # @return [Boolean]
        def contains_aggregate_functions?
          aggregate_function_names = %w[COUNT MAX MIN SUM AVG]
          ast.expr_list.any? do |select_field_node|
            aggregate_function_names.include?(select_field_node.expr.func&.function_name&.upcase)
          end
        end

        # Whether AST has `GROUP BY` clause
        # @return [Boolean]
        def group_by_clause?
          !ast.group_by.empty?
        end

        # Whether AST has `LIMIT` clause
        # @return [Boolean]
        def limit_clause?
          !!ast.limit_count
        end

        private

        # @return [GDA::SQL::Statement]
        # @raise [ArgumentError] called from subquery
        def statement
          return @statement if @statement

          raise ArgumentError, "@sql is required" unless @sql

          @statement = ::GDA::SQL::Parser.new.parse(RuboCop::Isucon::GDA.normalize_sql(@sql))
        end

        # @param operand [GDA::Nodes::Expr]
        # @return [RuboCop::Isucon::GDA::WhereOperand]
        def create_where_operand(operand)
          WhereOperand.new(value: operand.value.gsub(/^.+\./, ""), node: operand)
        end

        # @param operand [GDA::Nodes::Expr]
        # @return [RuboCop::Isucon::GDA::JoinOperand]
        def create_join_operand(operand)
          table_name_or_as, column_name = operand.value.split(".", 2)

          if (target = from_targets.find { |t| table_name_or_as == t[:table_name] })
            return JoinOperand.new(table_name: target[:table_name], column_name: column_name, as: nil, node: operand)
          end

          if (target = from_targets.find { |t| table_name_or_as == t[:as] })
            return JoinOperand.new(table_name: target[:table_name], column_name: column_name, as: target[:as], node: operand)
          end

          JoinOperand.new(table_name: nil, column_name: column_name, as: nil, node: operand)
        end

        # @return [Hash]
        def from_targets
          @from_targets ||= ast.from.targets.map { |target| { table_name: target.table_name, as: target.as } }
        end
      end
    end
  end
end
