# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Helper methods for {RuboCop::Cop::Isucon::Sinatra}
        module SinatraMethods
          extend NodePattern::Macros

          # @!method subclass_of_sinatra_base?(node)
          #   Whether match to `class AnyClass < Sinatra::Base` node
          #   @param node [RuboCop::AST::Node]
          #   @return [Boolean]
          def_node_matcher :subclass_of_sinatra_base?, <<~PATTERN
            (class (const nil? _) (const (const nil? :Sinatra) :Base) ...)
          PATTERN

          # @!method subclass_of_sinatra_base_contains_logging?(node)
          #   Whether match to `class AnyClass < Sinatra::Base` node and contains :logging configuration
          #   @param node [RuboCop::AST::Node]
          #   @return [Boolean]
          def_node_matcher :subclass_of_sinatra_base_contains_logging?, <<~PATTERN
            (class (const nil? _) (const (const nil? :Sinatra) :Base) ... `(send nil? _ (sym :logging)))
          PATTERN

          # Whether parent node match to `class AnyClass < Sinatra::Base` node
          # @param node [RuboCop::AST::Node]
          # @return [Boolean]
          def parent_is_sinatra_app?(node)
            node.each_ancestor.any? { |ancestor| subclass_of_sinatra_base?(ancestor) }
          end
        end
      end
    end
  end
end
