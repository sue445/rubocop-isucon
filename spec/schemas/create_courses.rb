# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  # c.f. https://github.com/isucon/isucon11-final/blob/dd22bc5cea4d8acda14c2596bcfe10e07f19018c/webapp/sql/1_schema.sql#L20-L34
  create_table :courses do |t|
    t.string  :code,        null: false, index: { unique: true }
    t.string  :type,        null: false # TODO: use enum
    t.string  :name,        null: false
    t.text    :description, null: false
    t.boolean :credit,      null: false
    t.boolean :period,      null: false
    t.string  :day_of_week, null: false # TODO: use enum
    t.string  :teacher_id,  null: false
    t.text    :keywords,    null: false
    t.string  :status,      null: false # TODO: use enum
  end
end
