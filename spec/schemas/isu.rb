# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :users do |t|
    t.string :jia_isu_uuid
    t.string :name
    t.column :image, :binary, limit: 16.megabyte
    t.string :character
    t.string :jia_user_id

    t.timestamps
  end
end
