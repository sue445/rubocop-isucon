# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :login_log do |t|
    t.datetime :created_at, null: false
    t.integer  :user_id
    t.string   :login,      null: false
    t.string   :ip,         null: false
    t.boolean  :succeeded,  null: false
  end
end
