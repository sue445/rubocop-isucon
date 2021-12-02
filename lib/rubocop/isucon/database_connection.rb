# frozen_string_literal: true

module RuboCop
  module Isucon
    # Manage database connection
    class DatabaseConnection
      # @param database_config [Hash] Same as `ActiveRecord::Base.establish_connection` argument
      # @see https://api.rubyonrails.org/classes/ActiveRecord/ConnectionHandling.html#method-i-establish_connection
      def initialize(database_config)
        ActiveRecord::Base.establish_connection(database_config)
        @column_names_by_table = {}
        @indexes_by_table = {}
        @primary_keys_by_table = {}
      end

      # @param table_name [String]
      # @return [Array<String>]
      def column_names(table_name)
        @column_names_by_table[table_name] ||= ActiveRecord::Base.connection.columns(table_name).map(&:name)
      end

      # @param table_name [String]
      # @return [Array<ActiveRecord::ConnectionAdapters::IndexDefinition>]
      # @see https://github.com/rails/rails/blob/v6.1.4.1/activerecord/lib/active_record/connection_adapters/abstract/schema_definitions.rb#L8
      def indexes(table_name)
        @indexes_by_table[table_name] ||= ActiveRecord::Base.connection.indexes(table_name)
      end

      # @param table_name [String]
      # @return [Array<Array<String>>] column names of indexes
      def unique_index_columns(table_name)
        indexes(table_name).select(&:unique).map(&:columns)
      end

      # @param table_name [String]
      # @return [Array<String>] primary key's column names
      def primary_keys(table_name)
        @primary_keys_by_table[table_name] ||= ActiveRecord::Base.connection.primary_keys(table_name)
      end
    end
  end
end
