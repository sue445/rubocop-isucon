# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module Isucon
    # A plugin that integrates RuboCop Performance with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-isucon",
          version: VERSION,
          homepage: "https://github.com/sue445/rubocop-isucon",
          description: "RuboCop plugin for ruby reference implementation of ISUCON",
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join("../../../config/default.yml"),
        )
      end
    end
  end
end
