# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
        # Avoid `SELECT *` in `db.xquery`
        #
        # @note If `Database` isn't configured, auto-correct will not be available. (Only offense detection can be used)
        #
        # @note This cop replaces `SELECT *` with a `SELECT` by the columns present in the table (e.g. `SELECT id, name`),
        #       but does not check whether the columns are actually used.
        #       Please manually delete unused columns after auto corrected
        #
        # @example
        #   # bad
        #   db.xquery('SELECT * FROM users')
        #
        #   # bad
        #   db.xquery('SELECT users.* FROM users')
        #
        #   # good
        #   db.xquery('SELECT id, name FROM users')
        #
        #   # good
        #   db.xquery('SELECT users.id, users.name FROM users')
        #
        class SelectAsterisk < Base
          include Mixin::DatabaseMethods
          include Mixin::Mysql2XqueryMethods

          extend AutoCorrector

          MSG = "Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)"

          TODO = "# TODO: Remove needless columns if necessary\n"

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            with_xquery(node) do |type, root_gda|
              next unless root_gda

              check_and_register_offence(type: type, root_gda: root_gda, node: node)
            end
          rescue ActiveRecord::StatementInvalid => e
            print_warning(cop_name: "Isucon/Mysql2/SelectAsterisk", error: e)
          end

          private

          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param root_gda [RuboCop::Isucon::GDA::Client]
          # @param node [RuboCop::AST::Node]
          def check_and_register_offence(type:, root_gda:, node:)
            root_gda.visit_all do |gda|
              next unless gda.ast.respond_to?(:expr_list)

              gda.ast.expr_list.each do |select_field_node|
                check_and_register_offence_for_select_field_node(
                  type: type, node: node, gda: gda,
                  select_field_node: select_field_node
                )
              end
            end
          end

          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param node [RuboCop::AST::Node]
          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param select_field_node [GDA::Nodes::SelectField]
          def check_and_register_offence_for_select_field_node(type:, node:, gda:, select_field_node:)
            return unless select_field_node.respond_to?(:expr)

            select_field = parse_select_field_node(select_field_node)

            return unless select_field[:column_name] == "*"

            loc = offense_location(type: type, node: node, gda_location: select_field_node.expr.location)
            return unless loc

            add_offense(loc) do |corrector|
              perform_autocorrect(corrector: corrector, loc: loc, gda: gda, node: node,
                                  select_table_name: select_field[:table_name])
            end
          end

          # @param select_field_node [GDA::Nodes::SelectField]
          # @return [Hash<Symbol, String>] table_name, column_name
          def parse_select_field_node(select_field_node)
            column_elements = select_field_node.expr.value.split(".", 2)

            case column_elements.count
            when 1
              return { column_name: column_elements[0] }
            when 2
              return { table_name: column_elements[0], column_name: column_elements[1] }
            end

            {}
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param loc [Parser::Source::Range]
          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param node [RuboCop::AST::Node]
          # @param select_table_name [String,nil] table names included in the SELECT clause
          def perform_autocorrect(corrector:, loc:, gda:, node:, select_table_name:)
            return unless enabled_database?
            return if gda.table_names.empty?

            if select_table_name
              return unless gda.table_names.include?(select_table_name)

              replace_asterisk(corrector: corrector, loc: loc, table_name: select_table_name, table_prefix: true)
            else
              return unless gda.table_names.length == 1

              replace_asterisk(corrector: corrector, loc: loc, table_name: gda.table_names[0], table_prefix: false)
            end

            insert_todo_comment(corrector: corrector, node: node)
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param loc [Parser::Source::Range]
          # @param table_name [String]
          # @param table_prefix [Boolean] Whether add table name to prefix (e.g. `users`.`name`)
          def replace_asterisk(corrector:, loc:, table_name:, table_prefix:)
            select_columns = columns_in_select_clause(table_name: table_name, table_prefix: table_prefix)
            corrector.replace(loc, select_columns)
          end

          # @param table_name [String]
          # @param table_prefix [Boolean] Whether add table name to prefix (e.g. `users`.`name`)
          # @return [String]
          def columns_in_select_clause(table_name:, table_prefix:)
            column_names = connection.column_names(table_name)

            column_names.map do |column|
              if table_prefix
                "`#{table_name}`.`#{column}`"
              else
                "`#{column}`"
              end
            end.join(", ")
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param node [RuboCop::AST::Node]
          def insert_todo_comment(corrector:, node:)
            current_line = node.loc.expression.line
            current_line_range = node.loc.expression.source_buffer.line_range(current_line)

            indent = node_indent_level(node)
            comment_line = (" " * indent) + TODO
            corrector.insert_before(current_line_range, comment_line)
          end

          # @param node [RuboCop::AST::Node]
          # @return [Integer]
          def node_indent_level(node)
            node.loc.expression.source_line =~ /^(\s+)/
            return 0 unless Regexp.last_match(1)

            Regexp.last_match(1).length
          end
        end
      end
    end
  end
end
