# frozen_string_literal: true

require_relative "isucon/version"

module RuboCop
  # RuboCop Isucon project namespace
  module Isucon
    class Error < StandardError; end

    # `Database` isn't configured in `.rubocop.yml`
    class DatabaseConfigurationError < Error; end

    # Your code goes here...
    PROJECT_ROOT   = Pathname.new(__dir__).parent.parent.expand_path.freeze
    CONFIG_DEFAULT = PROJECT_ROOT.join("config", "default.yml").freeze
    CONFIG         = YAML.safe_load(CONFIG_DEFAULT.read).freeze

    private_constant(:CONFIG_DEFAULT, :PROJECT_ROOT)
  end
end
