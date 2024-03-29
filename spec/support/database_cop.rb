# frozen_string_literal: true

RSpec.shared_context :database_cop, shared_context: :metadata do
  let(:schema) { "" }

  let(:cop_config) do
    {
      "Database" => {
        "adapter" => "sqlite3",
        "database" => ":memory:",
        "timeout" => 500,
      },
    }
  end

  before do
    # Setup active_record connection before create database and schema
    cop.connection

    # db:create
    ActiveRecord::Tasks::DatabaseTasks.create(cop_config["Database"])

    unless schema.empty?
      Array(schema).each do |file|
        load spec_dir.join(file)
      end
    end
  end
end
