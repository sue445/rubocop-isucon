# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Sqlite3
        # Check for `JOIN` without index
        #
        # @note If `Database` isn't configured, this cop's feature (offense detection and auto-correct) will not be available.
        #
        # @example
        #   # bad (user_id is not indexed)
        #   db.execute('SELECT id, title FROM articles JOIN users ON users.id = articles.user_id')
        #
        #   # good (user_id is indexed)
        #   db.execute('SELECT id, title FROM articles JOIN users ON users.id = articles.user_id')
        #
        class JoinWithoutIndex < Base
          include Mixin::DatabaseMethods
          include Mixin::Sqlite3ExecuteMethods
          include Mixin::JoinWithoutIndexMethods

          MSG = "This join clause doesn't seem to have an index. " \
                "(e.g. `CREATE INDEX index_%<table_name>s_%<column_name>s ON %<table_name>s (%<column_name>s)`)"

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            with_error_handling(node) do
              return unless enabled_database?

              with_db_execute(node) do |type, root_gda|
                check_and_register_offence(type: type, root_gda: root_gda, node: node)
              end
            end
          end

          private

          # @param table_name [String]
          # @param column_name [String]
          # @return [String]
          def generate_offense_message(table_name:, column_name:)
            format(MSG, table_name: table_name, column_name: column_name)
          end
        end
      end
    end
  end
end