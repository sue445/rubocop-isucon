# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  # c.f. https://github.com/isucon/isucon8-qualify/blob/fb07e6dc4790d8203d87027d5625a1fc055c2ed6/db/schema.sql#L9-L15
  create_table :events do |t|
    t.string  :title,     null: false
    t.boolean :public_fg, null: false
    t.boolean :closed_fg, null: false
    t.integer :price,     null: false
    t.timestamps
  end
end
