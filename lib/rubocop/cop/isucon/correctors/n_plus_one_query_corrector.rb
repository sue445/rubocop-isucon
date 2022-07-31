# frozen_string_literal: true

require_relative "n_plus_one_query_corrector/correctable_methods"
require_relative "n_plus_one_query_corrector/replace_methods"

module RuboCop
  module Cop
    module Isucon
      module Correctors
        # rubocop:disable Layout/LineLength

        # Corrector for {RuboCop::Cop::Isucon::Mysql2::NPlusOneQuery}
        #
        # @example Before
        #   courses.map do |course|
        #     teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ?', course[:teacher_id]).first
        #   end
        #
        # @example After
        #   courses.map do |course|
        #     @users_by_id ||= db.xquery('SELECT * FROM `users` WHERE `id` IN (?)', courses.map { |course| course[:teacher_id] }).each_with_object({}) { |v, hash| hash[v[:id]] = v }
        #     teacher = @users_by_id[course[:teacher_id]]
        #   end
        class NPlusOneQueryCorrector
          # rubocop:enable Layout/LineLength

          include Mixin::Mysql2XqueryMethods
          include CorrectableMethods
          include ReplaceMethods

          # @return [RuboCop::Cop::Corrector]
          attr_reader :corrector

          # @return [RuboCop::AST::Node]
          attr_reader :current_node

          # @return [RuboCop::AST::Node]
          attr_reader :parent_node

          # @return [Symbol]
          attr_reader :type

          # @return [RuboCop::Isucon::GDA::Client]
          attr_reader :gda

          # @return [RuboCop::Isucon::DatabaseConnection]
          attr_reader :connection

          # @return [Boolean]
          attr_reader :is_array_arg

          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          # @param parent_node [RuboCop::AST::Node]
          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param connection [RuboCop::Isucon::DatabaseConnection]
          # @param is_array_arg [Boolean]
          def initialize(corrector:, current_node:, parent_node:, type:, gda:, connection:, is_array_arg:) # rubocop:disable Metrics/ParameterLists
            @corrector = corrector
            @current_node = current_node
            @parent_node = parent_node
            @type = type
            @gda = gda
            @connection = connection
            @is_array_arg = is_array_arg
          end

          def correct
            replace if correctable?
          end

          private

          def array_arg?
            is_array_arg
          end

          # @return [RuboCop::AST::Node,nil]
          def parent_receiver
            parent_node.child_nodes&.first&.receiver
          end

          # @return [RuboCop::Isucon::GDA::NodeLocation]
          def where_condition_gda_loc
            gda.where_nodes.first.location
          end

          # @return [String,nil]
          def where_column
            matched = where_condition_gda_loc&.body&.match(/([^\s]+)\s*=\s*\?/)

            return nil unless matched

            matched[1]
          end

          # @return [RuboCop::AST::Node]
          def xquery_arg
            return current_node.child_nodes[2].child_nodes[0] if array_arg? && current_node.child_nodes[2]&.array_type?

            current_node.child_nodes[2]
          end

          # @return [RuboCop::AST::Node]
          def xquery_chained_method
            current_node.parent.node_parts[1]
          end

          # @return [String]
          def where_column_without_quote
            where_column&.delete("`")
          end

          # @return [RuboCop::AST::Node,nil]
          def xquery_lvar
            current_node.parent&.parent
          end
        end
      end
    end
  end
end
