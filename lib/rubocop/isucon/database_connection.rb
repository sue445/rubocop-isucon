# frozen_string_literal: true

module RuboCop
  module Isucon
    # Manage database connection
    class DatabaseConnection
      # @param [Hash]
      def initialize(database_config)
        ActiveRecord::Base.establish_connection(database_config)
        @column_names_by_table = {}
        @indexes_by_table = {}
        @primary_keys_by_table = {}
      end

      # @param table_name [String]
      # @return [Array<String>]
      def column_names(table_name)
        return @column_names_by_table[table_name] if @column_names_by_table[table_name]

        columns = ActiveRecord::Base.connection.columns(table_name)
        @column_names_by_table[table_name] = columns.map(&:name)
      end

      # @param table_name [String]
      # @return [Array<ActiveRecord::ConnectionAdapters::IndexDefinition>]
      # @see [ActiveRecord::ConnectionAdapters::TableDefinition#indexes]
      def indexes(table_name)
        return @indexes_by_table[table_name] if @indexes_by_table[table_name]

        @indexes_by_table[table_name] = ActiveRecord::Base.connection.indexes(table_name)
      end

      # @param table_name [String]
      # @return [Array<String>]
      def primary_keys(table_name)
        return @primary_keys_by_table[table_name] if @primary_keys_by_table[table_name]

        @primary_keys_by_table[table_name] = ActiveRecord::Base.connection.primary_keys(table_name)
      end
    end
  end
end
