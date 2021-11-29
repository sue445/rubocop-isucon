# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Database util methods for {RuboCop::Cop::Isucon::Mysql2}
        module DatabaseMethods
          # @return [RuboCop::Isucon::DatabaseConnection]
          # @raise [RuboCop::Isucon::DatabaseConfigurationError] `Database` isn't configured in `.rubocop.yml`
          def connection
            return @connection if @connection

            unless enabled_database?
              raise RuboCop::Isucon::DatabaseConfigurationError, "`Database` isn't configured in `.rubocop.yml`"
            end

            @connection = RuboCop::Isucon::DatabaseConnection.new(cop_config["Database"])
          end

          # @return [Boolean]
          def enabled_database?
            !!cop_config["Database"]
          end

          # @param table_names [Array<String>]
          # @param column_name [String]
          # @return [String,nil]
          def find_table_name_from_column_name(table_names:, column_name:)
            table_names.each do |table_name|
              column_names = connection.column_names(table_name)
              return table_name if column_names.include?(column_name)
            end
            nil
          end
        end
      end
    end
  end
end
