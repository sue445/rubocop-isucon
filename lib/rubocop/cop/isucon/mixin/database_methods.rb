# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Database util methods for Isucon/Mysql cops
        module DatabaseMethods
          # @return [RuboCop::Isucon::DatabaseConnection]
          # @raise [RuboCop::Cop::Isucon::DatabaseConfigurationError] Database isn't configured in .rubocop.yml
          def connection
            raise RuboCop::Cop::Isucon::DatabaseConfigurationError, "`Database` isn't configured in `.rubocop.yml`" unless enabled_database?

            @connection ||= RuboCop::Isucon::DatabaseConnection.new(cop_config["Database"])
          end

          # @return [Boolean]
          def enabled_database?
            !!cop_config["Database"]
          end
        end
      end
    end
  end
end
