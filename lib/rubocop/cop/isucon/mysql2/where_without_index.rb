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

            with_xquery(node) do |type, root_gda|
              next unless root_gda
              next if exists_index_in_where_clause_columns?(root_gda)

              register_offense(type: type, node: node, root_gda: root_gda)
            end
          end

          private

          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param node [RuboCop::AST::Node]
          # @param root_gda [RuboCop::Isucon::GDA::Client]
          def register_offense(type:, node:, root_gda:)
            root_gda.visit_all do |gda|
              next if gda.where_nodes.empty?

              loc = offense_location(type: type, node: node, gda_location: gda.where_nodes.first.location)
              next unless loc

              message = offense_message(gda)
              add_offense(loc, message: message)
            end
          end

          # @param gda [RuboCop::Isucon::GDA::Client]
          def offense_message(gda)
            column_name = gda.where_conditions[0].column_operand
            table_name = find_table_name_from_column_name(table_names: gda.table_names, column_name: column_name)
            format(MSG, table_name: table_name, column_name: column_name)
          end

          # @param root_gda [RuboCop::Isucon::GDA::Client]
          # @return [Boolean]
          def exists_index_in_where_clause_columns?(root_gda)
            root_gda.visit_all do |gda|
              gda.table_names.each do |table_name|
                return true if covered_where_column_in_index?(gda: gda, table_name: table_name)
                return true if covered_where_column_in_primary_key?(gda: gda, table_name: table_name)
              end
            end

            false
          end

          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param table_name [String]
          # @return [Boolean]
          def covered_where_column_in_index?(gda:, table_name:)
            indexes = connection.indexes(table_name)
            index_first_columns = indexes.map { |index| index.columns[0] }

            gda.where_conditions.any? do |condition|
              index_first_columns.include?(condition.column_operand)
            end
          end

          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param table_name [String]
          # @return [Boolean]
          def covered_where_column_in_primary_key?(gda:, table_name:)
            primary_keys = connection.primary_keys(table_name)
            return false if primary_keys.empty?

            where_columns = gda.where_conditions.map(&:column_operand)
            primary_keys.all? { |primary_key| where_columns.include?(primary_key) }
          end
        end
      end
    end
  end
end
