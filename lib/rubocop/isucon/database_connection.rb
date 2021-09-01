module RuboCop
  module Isucon
    class DatabaseConnection
      # @param [Hash]
      def initialize(database_config)
        ActiveRecord::Base.establish_connection(database_config)
      end

      # @param table_name [String]
      # @return [Array<String>]
      def column_names(table_name)
        columns = ActiveRecord::Base.connection.columns(table_name)
        columns.map(&:name)
      end
    end
  end
end
