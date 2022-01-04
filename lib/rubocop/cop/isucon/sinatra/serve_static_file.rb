# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Sinatra
        # Serve static files on front server (e.g. nginx) instead of sinatra app
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
          include Mixin::SinatraMethods

          MSG = "Serve static files on front server (e.g. nginx) instead of sinatra app"

          def_node_matcher :file_read_method?, <<~PATTERN
            (send (const nil? :File) :read ...)
          PATTERN

          def_node_matcher :get_block?, <<~PATTERN
            (block (send nil? :get ...) ...)
          PATTERN

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            return unless parent_is_sinatra_app?(node)
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
            node.each_ancestor.find { |ancestor| get_block?(ancestor) }
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
