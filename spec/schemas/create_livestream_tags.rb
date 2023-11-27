# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :livestream_tags do |t|
    t.integer :livestream_id, null: false
    t.integer :tag_id, null: false
  end
end
