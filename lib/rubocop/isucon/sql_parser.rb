# frozen_string_literal: true

module RuboCop
  module Isucon
    # SQL Parser
    module SqlParser
      # Parse table names in SQL (SELECT, UPDATE, INSERT, DELETE)
      # @param sql [String]
      # @return [Array<String>]
      def self.parse_tables(sql)
        # Remove `FOR UPDATE` in `SELECT`
        sql = sql.gsub(/FOR\s+UPDATE/i, "")

        # Remove `ON DUPLICATE KEY UPDATE` in `INSERT`
        sql = sql.gsub(/ON\s+DUPLICATE\s+KEY\s+UPDATE/i, "")

        sql.scan(/(?:FROM|INTO|UPDATE|JOIN)\s+([^(]+?)[\s(]/i)
           .map { |matched| matched[0].strip.gsub("`", "") }.reject(&:empty?).uniq
      end
    end
  end
end
