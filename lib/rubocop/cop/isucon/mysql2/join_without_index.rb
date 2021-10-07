# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
        # Check for `JOIN` without index
        #
        # @note If `Database` isn't configured, this cop's feature (offense detection and auto-correct) will not be available.
        #
        # @example
        #   # bad (user_id is not indexed)
        #   db.xquery('SELECT id, title FROM articles JOIN users ON users.id = articles.user_id')
        #
        #   # good (user_id is indexed)
        #   db.xquery('SELECT id, title FROM articles JOIN users ON users.id = articles.user_id')
        #
        class JoinWithoutIndex < Base
          include Mixin::DatabaseMethods
          include Mixin::Mysql2Methods

          MSG = "This join clause doesn't seem to have an index. " \
                "(e.g. 'ALTER TABLE `%<table_name>s` ADD INDEX `index_%<column_name>s` (%<column_name>s)')"

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            return unless enabled_database?

            with_xquery(node) do |type, root_gda|
              check_and_register_offence(type: type, root_gda: root_gda, node: node)
            end
          end

          private

          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param root_gda [RuboCop::Isucon::GDA::Client]
          # @param node [RuboCop::AST::Node]
          def check_and_register_offence(type:, root_gda:, node:)
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
            format(MSG, table_name: join_operand.table_name, column_name: join_operand.column_name)
          end
        end
      end
    end
  end
end
