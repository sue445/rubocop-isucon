# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :reservations do |t|
    t.integer :event_id, null: false
    t.integer :sheet_id, null: false
    t.integer :user_id, null: false
    t.datetime :reserved_at, null: false
    t.datetime :canceled_at, default: nil
  end
end
