# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
        # Check for `WHERE` without index
        #
        # @note If `Database` isn't configured, this cop's feature (offense detection and auto-correct) will not be available.
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

          MSG = "This where clause doesn't seem to have an index. " \
                "(e.g. 'ALTER TABLE `%<table_name>s` ADD INDEX `index_%<column_name>s` (%<column_name>s)')"

          def_node_search :find_xquery, <<-PATTERN
            (send (send nil? _) {:xquery | :query} (${str dstr} $...) ...)
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity
            return unless enabled_database?

            find_xquery(node) do |type, params|
              sql =
                case type
                when :str
                  params[0]
                when :dstr
                  params.map(&:value).join
                end

              gda = RuboCop::Isucon::GdaHelper.new(sql)

              table_names = gda.table_names

              next if exists_index_in_where_clause_columns?(gda, table_names)

              loc =
                case type
                when :str
                  sql_where_location_for_str(node, sql)
                when :dstr
                  sql_where_location_for_dstr(node)
                end

              next unless loc

              column_name = gda.where_clause[0].column_operand
              table_name = find_table_name_from_column_name(table_names, column_name)
              message = format(MSG, table_name: table_name, column_name: column_name)
              add_offense(loc, message: message)
            end
          end

          private

          # @param node [RuboCop::AST::StrNode]
          # @param sql [String]
          def sql_where_location_for_str(node, sql)
            select_pos = sql_select_location_begin_position(node)
            return nil unless select_pos

            where_pos = sql.index(/WHERE/i)

            begin_pos = select_pos + where_pos
            end_pos = begin_pos + 5

            Parser::Source::Range.new(node.loc.expression.source_buffer, begin_pos, end_pos)
          end

          # @param node [RuboCop::AST::DstrNode]
          def sql_where_location_for_dstr(node)
            dstr_node = node.child_nodes[1]
            begin_pos = text_begin_position_within_heredoc(dstr_node, /WHERE/i)
            return nil unless begin_pos

            end_pos = begin_pos + 5

            Parser::Source::Range.new(node.loc.expression.source_buffer, begin_pos, end_pos)
          end

          # @param gda [RuboCop::Isucon::GdaHelper]
          # @param table_names [Array<String>]
          # @return [Boolean]
          def exists_index_in_where_clause_columns?(gda, table_names) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
            table_names.each do |table_name|
              indexes = connection.indexes(table_name)
              index_first_columns = indexes.map { |index| index.columns[0] }

              return true if gda.where_clause.any? { |condition| index_first_columns.include?(condition.column_operand) }

              primary_keys = connection.primary_keys(table_name)
              unless primary_keys.empty?
                where_columns = gda.where_clause.map(&:column_operand)
                return true if primary_keys.all? { |primary_key| where_columns.include?(primary_key) }
              end
            end

            false
          end

          # @param table_names [Array<String>]
          # @param column_name [String]
          # @return [String,nil]
          def find_table_name_from_column_name(table_names, column_name)
            table_names.each do |table_name|
              column_names = connection.column_names(table_name)
              return table_name if column_names.include?(column_name)
            end
            nil
          end
        end
      end
    end
  end
end
