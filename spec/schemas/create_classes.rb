# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  # c.f. https://github.com/isucon/isucon11-final/blob/dd22bc5cea4d8acda14c2596bcfe10e07f19018c/webapp/sql/1_schema.sql#L45-L55
  create_table :classes do |t|
    t.string :course_id, null: false
    t.boolean :part, null: false
    t.string :title, null: false
    t.text :description, null: false
    t.boolean :submission_closed, null: false, default: false
  end

  add_index :classes, %i[course_id part], unique: true
end
