# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :isu do |t|
    t.string :jia_isu_uuid
    t.string :name
    t.column :image, :binary, limit: 16 * (1024**2) # 16MB
    t.string :character
    t.string :jia_user_id

    t.timestamps
  end
end
