# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  # c.f. https://github.com/isucon/isucon8-final/blob/38c4f6e20388d1c4f1ed393fb75b38d472e44abf/webapp/sql/isucoin.sql
  create_table :trade do |t|
    t.integer :amount
    t.integer :price
    t.datetime :created_at
  end
end
