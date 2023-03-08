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
        #   db.xquery('SELECT id, title FROM articles WHERE user_id = ?', user_id)
        #
        #   # good (user_id is indexed)
        #   db.xquery('SELECT id, title FROM articles WHERE user_id = ?', user_id)
        #
        #   # good (id is primary key)
        #   db.xquery('SELECT id, title FROM articles WHERE id = ?', id)
        #
        class WhereWithoutIndex < Base
          include Mixin::Mysql2XqueryMethods
          include Mixin::WhereWithoutIndexMethods

          MSG = "This where clause doesn't seem to have an index. " \
                "(e.g. `ALTER TABLE %<table_name>s ADD INDEX index_%<column_name>s (%<column_name>s)`)"

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
