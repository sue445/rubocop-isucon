# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  add_index :reservations, %i[event_id sheet_id]
  add_index :reservations, :user_id
end
