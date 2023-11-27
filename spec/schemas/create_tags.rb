# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :tags do |t|
    t.string :name, null: false
  end

  add_index :tags, :name, unique: true
end
