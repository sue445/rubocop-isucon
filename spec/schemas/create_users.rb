# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  create_table :users do |t|
    t.string :name
    t.timestamps
  end
end
