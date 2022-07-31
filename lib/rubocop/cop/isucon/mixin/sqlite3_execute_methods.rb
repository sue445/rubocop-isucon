# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mixin
        # Helper methods for `db.execute` in AST
        module Sqlite3ExecuteMethods
          extend NodePattern::Macros

          include OffenceLocationMethods

          # @!method find_xquery(node)
          #   @param node [RuboCop::AST::Node]
          def_node_search :find_execute, <<~PATTERN
            (send _ {:execute | :get_first_row} (${str dstr lvar ivar cvar} $...) ...)
          PATTERN

          NON_STRING_WARNING_MSG = "Warning: non-string was passed to `execute` or `get_first_row` 1st argument. " \
                                   "So argument doesn't parsed as SQL (%<file_path>s:%<line_num>d)"

          # @param node [RuboCop::AST::Node]
          # @yieldparam type [Symbol] Node type. one of `:str`, `:dstr`
          # @yieldparam root_gda [RuboCop::Isucon::GDA::Client,nil]
          #
          # @note If arguments of `db.xquery` isn't string, `root_gda` is `nil`
          def with_db_execute(node)
            find_execute(node) do |type, params|
              sql = execute_param(type: type, params: params)

              unless sql
                warn format(NON_STRING_WARNING_MSG, file_path: processed_source.file_path, line_num: node.loc.expression.line)
              end

              root_gda = sql ? RuboCop::Isucon::GDA::Client.new(sql) : nil

              yield type, root_gda
            end
          end

          private

          # @return [Array<Symbol>]
          def db_query_methods
            %i[execute get_first_row]
          end

          # @param type [Symbol] Node type. one of `:str`, `:dstr`
          # @param params [Array<RuboCop::AST::Node>]
          # @return [String,nil]
          def execute_param(type:, params:)
            case type
            when :str
              return params[0]
            when :dstr
              if params.all? { |param| param.respond_to?(:value) }
                # heredoc
                return params.map(&:value).join
              end
            end
            nil
          end
        end
      end
    end
  end
end
