# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
        # Avoid `SELECT *` in `db.xquery`
        #
        # @note If `Database` isn't configured, auto-correct will not be available. (Only offense detection can be used)
        #
        # @example
        #   # bad
        #   db.xquery('SELECT * FROM users')
        #
        #   # good
        #   db.xquery('SELECT id, name FROM users')
        #
        class SelectAsterisk < Base
          include Mixin::DatabaseMethods
          include Mixin::Mysql2Methods

          extend AutoCorrector

          MSG = "Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)"

          # @param node [RuboCop::AST::Node]
          def on_send(node)
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
              gda.ast.expr_list.each do |select_field_node|
                next unless select_field_node.expr.value == "*"

                loc = offense_location(type: type, node: node, gda_location: select_field_node.expr.location)
                next unless loc

                add_offense(loc) do |corrector|
                  perform_autocorrect(corrector: corrector, loc: loc, gda: gda)
                end
              end
            end
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param loc [Parser::Source::Range]
          # @param gda [RuboCop::Isucon::GDA::Client]
          def perform_autocorrect(corrector:, loc:, gda:)
            return unless enabled_database?

            return unless gda.table_names.length == 1

            select_columns = columns_in_select_clause(gda.table_names[0])

            corrector.replace(loc, select_columns)
          end

          # @param table_name [String]
          # @return [String]
          def columns_in_select_clause(table_name)
            column_names = connection.column_names(table_name)
            column_names.map { |column| "`#{column}`" }.join(", ")
          end
        end
      end
    end
  end
end
