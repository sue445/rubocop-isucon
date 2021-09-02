# frozen_string_literal: true

module RuboCop
  module Isucon
    # Manage database connection
    class DatabaseConnection
      # @param [Hash]
      def initialize(database_config)
        ActiveRecord::Base.establish_connection(database_config)
        @column_names_by_table = {}
      end

      # @param table_name [String]
      # @return [Array<String>]
      def column_names(table_name)
        return @column_names_by_table[table_name] if @column_names_by_table[table_name]

        columns = ActiveRecord::Base.connection.columns(table_name)
        @column_names_by_table[table_name] = columns.map(&:name)
      end
    end
  end
end
