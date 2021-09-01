# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::DatabaseConnection do
  let(:connection) { RuboCop::Isucon::DatabaseConnection.new(database_config) }

  let(:database_config) do
    {
      adapter: "sqlite3",
      database: ":memory:",
      timeout: 500
    }.transform_keys(&:to_s)
  end

  describe "#column_names" do
    subject { connection.column_names("users") }

    before do
      connection

      # db:create
      ActiveRecord::Tasks::DatabaseTasks.create(database_config)

      load schema_dir.join("users.rb")
    end

    it { should contain_exactly("id", "name", "created_at", "updated_at") }
  end
end
