# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
        # TODO: Write cop description and example of bad / good code. For every
        # `SupportedStyle` and unique configuration, there needs to be examples.
        # Examples must have valid Ruby syntax. Do not use upticks.
        #
        # @safety
        #   Delete this section if the cop is not unsafe (`Safe: false` or
        #   `SafeAutoCorrect: false`), or use it to explain how the cop is
        #   unsafe.
        #
        # @example EnforcedStyle: bar (default)
        #   # Description of the `bar` style.
        #
        #   # bad
        #   bad_bar_method
        #
        #   # bad
        #   bad_bar_method(args)
        #
        #   # good
        #   good_bar_method
        #
        #   # good
        #   good_bar_method(args)
        #
        # @example EnforcedStyle: foo
        #   # Description of the `foo` style.
        #
        #   # bad
        #   bad_foo_method
        #
        #   # bad
        #   bad_foo_method(args)
        #
        #   # good
        #   good_foo_method
        #
        #   # good
        #   good_foo_method(args)
        #
        class ManyJoinTable < Base
          include Mixin::Mysql2XqueryMethods

          MSG = "Avoid SQL with lots of JOINs"

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            with_xquery(node) do |_, root_gda|
              check_and_register_offence(root_gda: root_gda, node: node)
            end
          end

          private

          # @param root_gda [RuboCop::Isucon::GDA::Client]
          # @param node [RuboCop::AST::Node]
          def check_and_register_offence(root_gda:, node:)
            return unless root_gda

            root_gda.visit_all do |gda|
              add_offense(node) if gda.table_names.count >= count_joins
            end
          end

          # @return [Integer]
          def count_joins
            cop_config["CountJoins"]
          end
        end
      end
    end
  end
end
