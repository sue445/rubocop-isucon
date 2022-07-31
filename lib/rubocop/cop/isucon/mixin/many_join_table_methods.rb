# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Common methods for {RuboCop::Cop::Isucon::Mysql2::ManyJoinTable}
        # and {RuboCop::Cop::Isucon::Sqlite3::ManyJoinTable}
        module ManyJoinTableMethods
          MSG = "Avoid SQL with lots of JOINs"

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            with_db_query(node) do |_, root_gda|
              check_and_register_offence(root_gda: root_gda, node: node)
            end
          end

          private

          # @param root_gda [RuboCop::Isucon::GDA::Client]
          # @param node [RuboCop::AST::Node]
          def check_and_register_offence(root_gda:, node:)
            return unless root_gda

            root_gda.visit_all do |gda|
              add_offense(node) if gda.table_names.count > count_tables
            end
          end

          # @return [Integer]
          def count_tables
            cop_config["CountTables"]
          end
        end
      end
    end
  end
end
