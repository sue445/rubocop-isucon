# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :registrations do |t|
    t.string :course_id
    t.string :user_id
  end
end
