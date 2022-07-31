# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Common methods for {RuboCop::Cop::Isucon::Mysql2::NPlusOneQuery}
        # and {RuboCop::Cop::Isucon::Sqlite3::NPlusOneQuery}
        module NPlusOneQueryMethods
          include Mixin::DatabaseMethods

          extend NodePattern::Macros

          MSG = "This looks like N+1 query."

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L38
          POST_CONDITION_LOOP_TYPES = %i[while_post until_post].freeze

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L39
          LOOP_TYPES = (POST_CONDITION_LOOP_TYPES + %i[while until for]).freeze

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L41
          ENUMERABLE_METHOD_NAMES = (Enumerable.instance_methods + [:each]).to_set.freeze

          def_node_matcher :csv_loop?, <<~PATTERN
            (block
              (send (const nil? :CSV) :parse ...)
              ...)
          PATTERN

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L68
          def_node_matcher :kernel_loop?, <<~PATTERN
            (block
              (send {nil? (const nil? :Kernel)} :loop)
              ...)
          PATTERN

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L74
          def_node_matcher :enumerable_loop?, <<~PATTERN
            (block
              (send $_ #enumerable_method? ...)
              ...)
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            with_error_handling(node) do
              with_db_query(node) do |type, root_gda|
                check_and_register_offence(node: node, type: type, root_gda: root_gda, is_array_arg: array_arg?)
              end
            end
          end

          private

          # @param node [RuboCop::AST::Node]
          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param root_gda [RuboCop::Isucon::GDA::Client]
          # @param is_array_arg [Boolean]
          def check_and_register_offence(node:, type:, root_gda:, is_array_arg:) # rubocop:disable Metrics/MethodLength
            return unless db_query_node?(node)

            receiver, = *node.children

            parent = parent_loop_node(receiver)
            return unless parent

            return if or_assignment_to_instance_variable?(node)

            add_offense(receiver) do |corrector|
              perform_autocorrect(
                corrector: corrector, current_node: receiver,
                parent_node: parent, type: type, gda: root_gda, is_array_arg: is_array_arg
              )
            end
          end

          # @param node [RuboCop::AST::Node]
          def db_query_node?(node)
            return db_query_methods.include?(node.children[1]) if node.children.count >= 3

            child = node.children.first
            return false unless child

            child.children.count >= 3 && db_query_methods.include?(child.children[1])
          end

          # Whether match to `@instance_var ||=`
          # @param node [RuboCop::AST::Node]
          # @return [Boolean]
          def or_assignment_to_instance_variable?(node)
            _or_assignment_to_instance_variable?(node.parent&.parent) ||
              _or_assignment_to_instance_variable?(node.parent&.parent&.parent)
          end

          # Whether match to `@instance_var ||=`
          # @param node [RuboCop::AST::Node]
          # @return [Boolean]
          def _or_assignment_to_instance_variable?(node)
            node&.or_asgn_type? && node.child_nodes&.first&.ivasgn_type?
          end

          # @param node [RuboCop::AST::Node]
          # @return [RuboCop::AST::Node]
          def parent_loop_node(node)
            node.each_ancestor.find { |ancestor| loop?(ancestor, node) }
          end

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L106
          def loop?(ancestor, node)
            keyword_loop?(ancestor.type) ||
              kernel_loop?(ancestor) ||
              node_within_enumerable_loop?(node, ancestor) ||
              csv_loop?(ancestor)
          end

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L112
          def keyword_loop?(type)
            LOOP_TYPES.include?(type)
          end

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L116
          def node_within_enumerable_loop?(node, ancestor)
            enumerable_loop?(ancestor) do |receiver|
              receiver != node && !receiver&.descendants&.include?(node)
            end
          end

          # @see https://github.com/rubocop/rubocop-performance/blob/v1.11.5/lib/rubocop/cop/performance/collection_literal_in_loop.rb#L130
          def enumerable_method?(method_name)
            ENUMERABLE_METHOD_NAMES.include?(method_name)
          end

          # @param corrector [RuboCop::Cop::Corrector]
          # @param current_node [RuboCop::AST::Node]
          # @param parent_node [RuboCop::AST::Node]
          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param gda [RuboCop::Isucon::GDA::Client]
          # @param is_array_arg [Boolean]
          def perform_autocorrect(corrector:, current_node:, parent_node:, type:, gda:, is_array_arg:) # rubocop:disable Metrics/ParameterLists
            return unless enabled_database?

            corrector = Correctors::NPlusOneQueryCorrector.new(
              corrector: corrector, current_node: current_node, is_array_arg: is_array_arg,
              parent_node: parent_node, type: type, gda: gda, connection: connection
            )
            corrector.correct
          end
        end
      end
    end
  end
end
