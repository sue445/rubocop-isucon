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
          include Mixin::Mysql2XqueryMethods
          include Mixin::SelectAsteriskMethods

          extend AutoCorrector
        end
      end
    end
  end
end
