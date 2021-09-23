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
            find_xquery(node) do |type, params|
              sql = xquery_param(type, params)

              next unless sql.match?(/^\s*SELECT\s+\*/i)

              loc = sql_select_location(type, node, sql)
              next unless loc

              add_offense(loc) do |corrector|
                perform_autocorrect(corrector, loc, sql)
              end
            end
          end

          private

          # @param type [Symbol]
          # @param node [RuboCop::AST::SendNode]
          # @param sql [String]
          # @return [Parser::Source::Range,nil]
          def sql_select_location(type, node, sql)
            case type
            when :str
              sql_select_location_for_str(node, sql)
            when :dstr
              sql_select_location_for_dstr(node)
            end
          end

          # @param node [RuboCop::AST::SendNode]
          # @param sql [String]
          # @return [Parser::Source::Range,nil]
          def sql_select_location_for_str(node, sql)
            asterisk_pos = sql.index("*")

            begin_pos = sql_select_location_begin_position(node)
            return nil unless begin_pos

            end_pos = begin_pos + asterisk_pos + 1

            Parser::Source::Range.new(node.loc.expression.source_buffer, begin_pos, end_pos)
          end

          # @param node [RuboCop::AST::SendNode]
          # @return [Parser::Source::Range,nil]
          def sql_select_location_for_dstr(node)
            dstr_node = node.child_nodes[1]

            begin_pos = text_begin_position_within_heredoc(dstr_node, /SELECT/i)
            end_pos   = text_begin_position_within_heredoc(dstr_node, /\*/)

            return nil if !begin_pos || !end_pos

            if node.loc.expression.source_buffer.source[begin_pos] == '"'
              begin_pos += 1
              end_pos += 1
            end
            Parser::Source::Range.new(node.loc.expression.source_buffer, begin_pos, end_pos + 1)
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param loc [Parser::Source::Range]
          # @param sql [String]
          def perform_autocorrect(corrector, loc, sql)
            return unless enabled_database?

            table_names = RuboCop::Isucon::SqlParser.parse_tables(sql)
            return unless table_names.length == 1

            asterisk_range = asterisk_range(loc)
            select_columns = columns_in_select_clause(table_names[0])

            corrector.replace(asterisk_range, select_columns)
          end

          # @param loc [Parser::Source::Range]
          # @return [Parser::Source::Range]
          def asterisk_range(loc)
            asterisk_pos = loc.source.index("*")
            begin_pos = loc.begin_pos + asterisk_pos
            Parser::Source::Range.new(loc.source_buffer, begin_pos, begin_pos + 1)
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
