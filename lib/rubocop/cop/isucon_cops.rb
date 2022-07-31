# frozen_string_literal: true

require_relative "isucon/mixin/database_methods"
require_relative "isucon/mixin/join_without_index_methods"
require_relative "isucon/mixin/offense_location_methods"
require_relative "isucon/mixin/mysql2_xquery_methods"
require_relative "isucon/mixin/select_asterisk_methods"
require_relative "isucon/mixin/sinatra_methods"
require_relative "isucon/mixin/sqlite3_execute_methods"
require_relative "isucon/mixin/where_without_index_methods"

require_relative "isucon/correctors/mysql2_n_plus_one_query_corrector"

require_relative "isucon/mysql2/join_without_index"
require_relative "isucon/mysql2/many_join_table"
require_relative "isucon/mysql2/n_plus_one_query"
require_relative "isucon/mysql2/prepare_execute"
require_relative "isucon/mysql2/select_asterisk"
require_relative "isucon/mysql2/where_without_index"
require_relative "isucon/sinatra/disable_logging"
require_relative "isucon/sinatra/logger"
require_relative "isucon/sinatra/rack_logger"
require_relative "isucon/sinatra/serve_static_file"
require_relative "isucon/shell/backtick"
require_relative "isucon/shell/system"
require_relative "isucon/sqlite3/join_without_index"
require_relative 'isucon/sqlite3/many_join_table'
require_relative "isucon/sqlite3/select_asterisk"
require_relative "isucon/sqlite3/where_without_index"
