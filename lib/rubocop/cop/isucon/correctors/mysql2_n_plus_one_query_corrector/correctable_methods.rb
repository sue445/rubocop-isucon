# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Correctors
        class Mysql2NPlusOneQueryCorrector
          # Check whether can correct
          module CorrectableMethods
            # @return [Boolean]
            def correctable?
              correctable_gda? && correctable_xquery_arg? &&
                correctable_parent_receiver? && current_node.child_nodes.count == 3 &&
                xquery_lvar.lvasgn_type? && %i[first last].include?(xquery_chained_method)
            end

            # @return [Boolean]
            def correctable_gda?
              gda&.select_query? && gda.table_names.count == 1 && !gda.limit_clause? &&
                !gda.group_by_clause? && !gda.contains_aggregate_functions? && where_clause_with_only_single_unique_key?
            end

            # @return [Boolean]
            def where_clause_with_only_single_unique_key?
              where_clause_with_only_primary_key? || where_clause_with_only_single_unique_index_column?
            end

            # @return [Boolean]
            def where_clause_with_only_primary_key?
              return false unless gda.where_nodes.count == 1

              primary_keys = connection.primary_keys(gda.table_names[0])
              return false unless primary_keys.count == 1

              primary_keys.first == where_column_without_quote
            end

            # @return [Boolean]
            def where_clause_with_only_single_unique_index_column?
              return false unless gda.where_nodes.count == 1

              unique_index_columns = connection.unique_index_columns(gda.table_names[0])
              unique_index_columns.each do |columns|
                return true if columns.count == 1 && columns.first == where_column_without_quote
              end

              false
            end

            # @return [Boolean]
            def correctable_xquery_arg? # rubocop:disable Metrics/AbcSize
              return false if !xquery_arg&.send_type? || xquery_arg.node_parts.count != 3 || !xquery_arg.node_parts[0].lvar_type?

              # Check one of hash[:key], hash["key"], hash.fetch(:key), hash.fetch("key")
              return false unless %i[[] fetch].include?(xquery_arg.node_parts[1])
              return false unless %i[sym str].include?(xquery_arg.node_parts[2].type)

              true
            end

            # @return [Boolean]
            def correctable_parent_receiver?
              parent_receiver.lvar_type? || parent_receiver.send_type?
            end
          end
        end
      end
    end
  end
end
