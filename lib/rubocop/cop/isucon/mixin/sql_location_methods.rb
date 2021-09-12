# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Helper methods for `db.xquery` in AST
        module SqlLocationMethods
          def sql_select_location_begin_position(node) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
            if node.child_nodes.count >= 2
              # without substitution (e.g. `db.xquery("SELECT * FROM users")`)
              query_node = node.child_nodes.find(&:str_type?)
              return nil unless query_node

              return query_node.loc.begin.end_pos
            end

            if node.child_nodes.count == 1
              if node.child_nodes[0].child_nodes.count > 1
                # with substitution (e.g. `rows = db.xquery("SELECT * FROM users")`)
                query_node = node.child_nodes[0].child_nodes.find(&:str_type?)
                return nil unless query_node

                return query_node.loc.begin.end_pos
              end

              # end of method
              query_node = node.child_nodes[0].child_nodes[0].child_nodes.find(&:str_type?)
              return nil unless query_node

              return query_node.loc.begin.end_pos
            end

            raise "loc.child_nodes is empty"
          end
        end
      end
    end
  end
end
