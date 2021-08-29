# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/isucon"
require_relative "rubocop/isucon/version"
require_relative "rubocop/isucon/inject"

RuboCop::Isucon::Inject.defaults!

require_relative "rubocop/cop/isucon_cops"
