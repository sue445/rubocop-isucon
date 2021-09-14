# frozen_string_literal: true

ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define(version: 1) do
  add_index :sheets, %i[rank num], unique: true
end
