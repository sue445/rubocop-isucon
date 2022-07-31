# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Sqlite3
        # Check for `WHERE` without index
        #
        # @note If `Database` isn't configured, this cop's feature (offense detection and auto-correct) will not be available.
        #
        # @example
        #   # bad (user_id is not indexed)
        #   db.execute('SELECT id, title FROM articles WHERE used_id = ?', [user_id])
        #
        #   # good (user_id is indexed)
        #   db.execute('SELECT id, title FROM articles WHERE used_id = ?', [user_id])
        #
        #   # good (id is primary key)
        #   db.execute('SELECT id, title FROM articles WHERE id = ?', [id])
        #
        class WhereWithoutIndex < Base
          include Mixin::Sqlite3ExecuteMethods
          include Mixin::WhereWithoutIndexMethods

          MSG = "This where clause doesn't seem to have an index. " \
                "(e.g. `CREATE INDEX index_%<table_name>s_%<column_name>s ON %<table_name>s (%<column_name>s)`)"

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
