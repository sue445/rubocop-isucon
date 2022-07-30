# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  # c.f. https://github.com/isucon/isucon12-qualify/blob/6e4552eca6e3f4b7b799a0573744734399de4dbb/webapp/sql/tenant/10_schema.sql#L5-L12
  create_table :competition do |t|
    t.integer :tenant_id, null: false
    t.string :title, null: false
    t.integer :finished_at, null: false
    t.timestamps
  end
end
