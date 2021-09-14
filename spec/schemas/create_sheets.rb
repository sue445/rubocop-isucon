# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :sheets do |t|
    t.string :rank, null: false
    t.integer :num, null: false
    t.integer :price, null: false
  end
end
