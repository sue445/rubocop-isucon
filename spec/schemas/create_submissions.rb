# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :submissions, primary_key: %i[user_id class_id] do |t|
    t.integer  :user_id,   null: false
    t.integer  :class_id,  null: false
    t.string   :file_name, null: false
    t.integer  :score
  end
end
