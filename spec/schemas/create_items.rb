# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  # c.f. https://github.com/isucon/isucon9-qualify/blob/34b3e785ebdd97d5c39a1263cbf56d1ae5e3ef91/webapp/sql/01_schema.sql#L21-L34
  create_table :items do |t|
    t.integer :seller_id, null: false
    t.integer :buyer_id, null: false, default: 0
    t.string  :status, null: false
    t.string  :name, null: false
    t.integer :price, null: false
    t.text    :description, null: false
    t.string  :image_name, null: false
    t.integer :category_id, null: false

    t.timestamps
  end

  add_index :items, :category_id
end
