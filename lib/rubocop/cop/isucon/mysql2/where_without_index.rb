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
          include Mixin::Mysql2Methods

          MSG = "This where clause doesn't seem to have an index. " \
                "(e.g. 'ALTER TABLE `%<table_name>s` ADD INDEX `index_%<column_name>s` (%<column_name>s)')"

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            return unless enabled_database?

            find_xquery(node) do |type, params|
              sql = xquery_param(type, params)

              root_gda = RuboCop::Isucon::GDA::Client.new(sql)

              next if exists_index_in_where_clause_columns?(root_gda)

              register_offense(type, node, root_gda)
            end
          end

          private

          def register_offense(type, node, root_gda)
            root_gda.visit_all do |gda|
              next if gda.where_conditions.empty?

              loc = offense_location(type, node, gda)
              next unless loc

              message = offense_message(gda)
              add_offense(loc, message: message)
            end
          end

          def offense_message(gda)
            column_name = gda.where_conditions[0].column_operand
            table_name = find_table_name_from_column_name(gda.table_names, column_name)
            format(MSG, table_name: table_name, column_name: column_name)
          end

          def offense_location(type, node, gda)
            where_first_ast = gda.where_nodes.first

            where_first_location = where_first_ast.location
            return nil unless where_first_location

            select_begin_pos = sql_select_begin_position(type, node)
            return nil unless select_begin_pos

            offset = heredoc_offset(type, node, where_first_location.body)
            begin_pos = select_begin_pos + where_first_location.begin_pos + offset
            end_pos = begin_pos + where_first_ast.location.length

            Parser::Source::Range.new(node.loc.expression.source_buffer, begin_pos, end_pos)
          end

          # @param type [Symbol]
          # @param node [RuboCop::AST::Node]
          # @return [Integer,nil]
          def sql_select_begin_position(type, node)
            case type
            when :str
              return sql_select_location_begin_position(node)
            when :dstr
              dstr_node = node.child_nodes[1]
              return dstr_node.loc.heredoc_body.begin_pos if dstr_node&.dstr_type?
            end
            nil
          end

          def heredoc_offset(type, node, offense_body)
            return 0 unless type == :dstr

            heredoc_indent_type = heredoc_indent_type(node)
            return 0 unless heredoc_indent_type == "~"

            dstr_node = node.child_nodes[1]
            return 0 if !dstr_node || !dstr_node.dstr_type?

            heredoc_body = dstr_node.loc.heredoc_body.source
            heredoc_indent_level = indent_level(heredoc_body)
            line_num = find_line_num(RuboCop::Isucon::GDA.normalize_sql(heredoc_body), offense_body)

            heredoc_indent_level * line_num
          end

          # Returns '~', '-' or nil
          def heredoc_indent_type(node)
            # c.f. https://github.com/rubocop/rubocop/blob/v1.21.0/lib/rubocop/cop/layout/heredoc_indentation.rb#L146-L149
            node.source[/<<([~-])/, 1]
          end

          # @param source [String]
          # @param str [String]
          def find_line_num(source, str)
            source.each_line.with_index do |line, i|
              return i + 1 if line.include?(str)
            end
            0
          end

          # @param root_gda [RuboCop::Isucon::GDA::Client]
          # @return [Boolean]
          def exists_index_in_where_clause_columns?(root_gda)
            root_gda.visit_all do |gda|
              gda.table_names.each do |table_name|
                return true if covered_where_column_in_index?(gda, table_name)
                return true if covered_where_column_in_primary_key?(gda, table_name)
              end
            end

            false
          end

          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param table_name [String]
          # @return [Boolean]
          def covered_where_column_in_index?(gda, table_name)
            indexes = connection.indexes(table_name)
            index_first_columns = indexes.map { |index| index.columns[0] }

            gda.where_conditions.any? do |condition|
              index_first_columns.include?(condition.column_operand)
            end
          end

          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param table_name [String]
          # @return [Boolean]
          def covered_where_column_in_primary_key?(gda, table_name)
            primary_keys = connection.primary_keys(table_name)
            return false if primary_keys.empty?

            where_columns = gda.where_conditions.map(&:column_operand)
            primary_keys.all? { |primary_key| where_columns.include?(primary_key) }
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
