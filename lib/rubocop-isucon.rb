# frozen_string_literal: true

require "rubocop"
require "active_record"
require "gda"

require_relative "rubocop/isucon"
require_relative "rubocop/isucon/version"
require_relative "rubocop/isucon/inject"
require_relative "rubocop/isucon/database_connection"
require_relative "rubocop/isucon/sql_parser"
require_relative "rubocop/isucon/gda_helper"
require_relative "rubocop/isucon/gda_helper/where_condition"
require_relative "rubocop/isucon/gda_ext"
require_relative "rubocop/isucon/gda_node_patcher"
require_relative "rubocop/isucon/gda_node_location"
require_relative "rubocop/isucon/gda"

RuboCop::Isucon::Inject.defaults!

require_relative "rubocop/cop/isucon_cops"
