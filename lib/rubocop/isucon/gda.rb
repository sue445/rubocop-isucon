# frozen_string_literal: true

require_relative "gda/client"
require_relative "gda/gda_ext"
require_relative "gda/join_condition"
require_relative "gda/join_operand"
require_relative "gda/node_location"
require_relative "gda/node_patcher"
require_relative "gda/where_condition"

module RuboCop
  module Isucon
    # `GDA` helper classes
    #
    # @see https://github.com/tenderlove/gda
    # @see https://gitlab.gnome.org/GNOME/libgda
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
