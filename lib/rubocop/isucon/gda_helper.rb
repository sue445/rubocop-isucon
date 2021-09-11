# frozen_string_literal: true

module RuboCop
  module Isucon
    # Wrapper for #{GDA}
    class GdaHelper
      PRACEHOLDER = "'__PRACEHOLDER__'"

      # @param sql [String]
      # @return [String]
      def self.normalize_sql(sql)
        sql.gsub("`", "").gsub("?", PRACEHOLDER)
      end
    end
  end
end
