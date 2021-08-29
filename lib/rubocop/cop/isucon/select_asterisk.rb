# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      # Avoid `SELECT *` in `db.xquery`
      #
      # @example
      #   # bad
      #   db.xquery('SELECT * FROM users')
      #
      #   # good
      #   db.xquery('SELECT id, name FROM users')
      #
      class SelectAsterisk < Base
        # In many cases, you can use a node matcher for matching node pattern.
        # See https://github.com/rubocop/rubocop-ast/blob/master/lib/rubocop/ast/node_pattern.rb
        #
        MSG = "Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)"

        def_node_search :find_xquery, <<-PATTERN
          (send (send nil? _) :xquery (str $_) ...)
        PATTERN

        def on_send(node)
          find_xquery(node) do |sql|
            if sql.match?(/^\s*SELECT\s+\*/i)
              loc = sql_select_location(node, sql)
              add_offense(loc)
            end
          end
        end

        private

        def sql_select_location(node, sql)
          asterisk_pos = sql.index("*")

          begin_pos =
            if node.child_nodes.count >= 2
              # without substitution (e.g. `db.xquery("SELECT * FROM users")`)
              node.child_nodes[1].loc.begin.end_pos
            elsif node.child_nodes.count == 1
              if node.child_nodes[0].child_nodes.count > 1
                # with substitution (e.g. `rows = db.xquery("SELECT * FROM users")`)
                node.child_nodes[0].child_nodes[1].loc.begin.end_pos
              else
                # end of method
                node.child_nodes[0].child_nodes[0].child_nodes[1].loc.begin.end_pos
              end
            else
              raise "node.child_nodes is empty"
            end

          end_pos = begin_pos + asterisk_pos + 1

          Parser::Source::Range.new(node.loc.expression.source_buffer, begin_pos, end_pos)
        end
      end
    end
  end
end
