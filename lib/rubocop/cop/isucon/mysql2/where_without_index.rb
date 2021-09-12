# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
        # Check for `WHERE` without index
        #
        # @example
        #   # bad (user_id is not indexed)
        #   db.xquery('SELECT id, title FROM articles WHERE used_id = ?', user_id)
        #
        #   # good (user_id is indexed)
        #   db.xquery('SELECT id, title FROM articles WHERE used_id = ?', user_id)
        #
        #   # good (id is primary key)
        #   db.xquery('SELECT id, title FROM articles WHERE id = ?', id)
        #
        class WhereWithoutIndex < Base
          include Mixin::DatabaseMethods
          include Mixin::SqlLocationMethods

          def_node_search :find_xquery, <<-PATTERN
            (send (send nil? _) {:xquery | :query} (str $_) ...)
          PATTERN

          def on_send(node) # rubocop:disable Metrics/MethodLength
            return unless enabled_database?

            find_xquery(node) do |sql|
              gda = RuboCop::Isucon::GdaHelper.new(sql)

              table_names = gda.table_names

              # TODO: Support join, subquery
              next unless table_names.count == 1

              table_name = table_names[0]

              next if exists_index_in_where_clause_columns?(gda, table_name)

              loc = sql_where_location(node, sql)
              next unless loc

              column_name = gda.where_clause[0].column_operand
              message = "This where clause doesn't seem to have an index. " \
                        "(e.g. 'ALTER TABLE `#{table_name}` ADD INDEX `index_#{column_name}` (#{column_name})')"
              add_offense(loc, message: message)
            end
          end

          private

          def sql_where_location(node, sql)
            select_pos = sql_select_location_begin_position(node)
            return nil unless select_pos

            where_pos = sql.index(/WHERE/i)

            begin_pos = select_pos + where_pos
            end_pos = begin_pos + 5

            Parser::Source::Range.new(node.loc.expression.source_buffer, begin_pos, end_pos)
          end

          # @param gda [RuboCop::Isucon::GdaHelper]
          # @param table_name [String]
          # @return [Boolean]
          def exists_index_in_where_clause_columns?(gda, table_name) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
            indexes = connection.indexes(table_name)
            index_first_columns = indexes.map { |index| index.columns[0] }

            return true if gda.where_clause.any? { |condition| index_first_columns.include?(condition.column_operand) }

            primary_keys = connection.primary_keys(table_name)
            unless primary_keys.empty?
              where_columns = gda.where_clause.map(&:column_operand)
              return true if primary_keys.all? { |primary_key| where_columns.include?(primary_key) }
            end

            false
          end
        end
      end
    end
  end
end
