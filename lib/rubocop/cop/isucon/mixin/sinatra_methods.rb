# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Util methods for {RuboCop::Cop::Isucon::Sinatra}
        module SinatraMethods
          extend NodePattern::Macros

          def_node_matcher :subclass_of_sinatra_base?, <<~PATTERN
            (class (const nil? _) (const (const nil? :Sinatra) :Base) ...)
          PATTERN

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
