# frozen_string_literal: true

require_relative "gda/client"
require_relative "gda/gda_ext"
require_relative "gda/node_location"
require_relative "gda/node_patcher"
require_relative "gda/where_condition"

module RuboCop
  module Isucon
    # `GDA` classes
    module GDA
      PRACEHOLDER = "0"

      # @param sql [String]
      # @return [String]
      def self.normalize_sql(sql)
        sql.gsub("`", " ").gsub("?", PRACEHOLDER)
      end
    end
  end
end
