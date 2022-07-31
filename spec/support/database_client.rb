# frozen_string_literal: true

# mysql2 wrapper for testing
class DatabaseClient
  # @param sql [String]
  # @param binds [Array]
  # @return [Array<Hash>]
  def xquery(sql, *binds)
    ActiveRecord::Base.connection.select_all(sql, nil, *binds)
  end

  # @param sql [String]
  # @param binds [Array]
  # @return [Array<Hash>]
  def execute(sql, binds)
    ActiveRecord::Base.connection.select_all(sql, nil, *binds)
  end
end
