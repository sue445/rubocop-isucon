# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Sinatra
        # Serve static files on front server (e.g. nginx)
        #
        # @example
        #   # bad
        #   class App < Sinatra::Base
        #     get '/' do
        #       content_type :html
        #       File.read(File.join(__dir__, '..', 'public', 'index.html'))
        #     end
        #   end
        #
        #   # good (e.g. Serve on nginx)
        #   location / {
        #     try_files $uri $uri/ /index.html;
        #   }
        #
        class ServeStaticFile < Base
          MSG = "Serve static files on front server (e.g. nginx)"

          def_node_matcher :file_read_method?, <<~PATTERN
            (send (const nil? :File) :read ...)
          PATTERN

          def_node_matcher :get_method?, <<~PATTERN
            (block (send nil? :get ...) ...)
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            return unless file_read_method?(node)

            parent = parent_get_node(node)
            return unless parent

            return unless end_of_block?(node: node, parent: parent)

            add_offense(parent)
          end

          private

          # @param node [RuboCop::AST::Node]
          # @return [RuboCop::AST::Node]
          def parent_get_node(node)
            node.each_ancestor.find { |ancestor| get_method?(ancestor) }
          end

          # @param node [RuboCop::AST::Node]
          # @param parent [RuboCop::AST::Node]
          # @return [Boolean]
          def end_of_block?(node:, parent:)
            parent.child_nodes.last&.child_nodes&.last == node
          end
        end
      end
    end
  end
end
