# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Shell
        # Avoid external command calls with backtick
        #
        # @example
        #   # bad
        #   def digest(src)
        #     `printf "%s" #{Shellwords.shellescape(src)} | openssl dgst -sha512 | sed 's/^.*= //'`.strip
        #   end
        #
        #   # bad
        #   def digest(src)
        #     %x(printf "%s" \#{Shellwords.shellescape(src)} | openssl dgst -sha512 | sed 's/^.*= //').strip
        #   end
        #
        #   # good
        #   def digest(src)
        #     OpenSSL::Digest::SHA512.hexdigest(src)
        #   end
        #
        #   # bad
        #   `curl -s https://example.com`
        #
        #   # good
        #   require "open-uri"
        #   URI.open("https://example.com").read
        #
        class Backtick < Base
          MSG = "Use pure-ruby code instead of external command execution if possible"

          # @param node [RuboCop::AST::Node]
          def on_xstr(node)
            add_offense(node)
          end
        end
      end
    end
  end
end
