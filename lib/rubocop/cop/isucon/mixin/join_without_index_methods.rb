# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Common methods for {RuboCop::Cop::Isucon::Mysql2::JoinWithoutIndex}
        # and {RuboCop::Cop::Isucon::Sqlite3::JoinWithoutIndex}
        module JoinWithoutIndexMethods
          include Mixin::DatabaseMethods

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            with_error_handling(node) do
              return unless enabled_database?

              with_db_query(node) do |type, root_gda|
                check_and_register_offence(type: type, root_gda: root_gda, node: node)
              end
            end
          end

          private

          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param root_gda [RuboCop::Isucon::GDA::Client]
          # @param node [RuboCop::AST::Node]
          def check_and_register_offence(type:, root_gda:, node:)
            return unless root_gda

            root_gda.visit_all do |gda|
              gda.join_conditions.each do |join_condition|
                join_operand = join_operand_without_index(join_condition)
                next unless join_operand

                register_offense(type: type, node: node, join_operand: join_operand)
              end
            end
          end

          # @param join_condition [RuboCop::Isucon::GDA::JoinCondition]
          # @return [RuboCop::Isucon::GDA::JoinOperand,nil]
          def join_operand_without_index(join_condition)
            join_condition.operands.each do |join_operand|
              next unless join_operand.table_name

              unless indexed_column?(table_name: join_operand.table_name, column_name: join_operand.column_name)
                return join_operand
              end
            end

            nil
          end

          # @param table_name [String]
          # @param column_name [String]
          # @return [Boolean]
          def indexed_column?(table_name:, column_name:)
            primary_keys = connection.primary_keys(table_name)

            return true if primary_keys&.first == column_name

            indexes = connection.indexes(table_name)
            index_first_columns = indexes.map { |index| index.columns[0] }
            index_first_columns.include?(column_name)
          end

          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param node [RuboCop::AST::Node]
          # @param join_operand [RuboCop::Isucon::GDA::JoinOperand]
          def register_offense(type:, node:, join_operand:)
            loc = offense_location(type: type, node: node, gda_location: join_operand.node.location)
            return unless loc

            message = offense_message(join_operand)
            add_offense(loc, message: message)
          end

          # @param join_operand [RuboCop::Isucon::GDA::JoinOperand]
          def offense_message(join_operand)
            generate_offense_message(table_name: join_operand.table_name, column_name: join_operand.column_name)
          end
        end
      end
    end
  end
end
