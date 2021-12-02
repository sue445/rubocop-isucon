# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::DatabaseConnection do
  let(:connection) { RuboCop::Isucon::DatabaseConnection.new(database_config) }

  let(:database_config) do
    {
      adapter: "sqlite3",
      database: ":memory:",
      timeout: 500,
    }.transform_keys(&:to_s)
  end

  describe "#column_names" do
    subject { connection.column_names("users") }

    before do
      # Setup active_record connection before create database and schema
      connection

      # db:create
      ActiveRecord::Tasks::DatabaseTasks.create(database_config)

      load spec_dir.join("schemas/create_users.rb")
    end

    it { should contain_exactly("id", "name", "created_at", "updated_at") }
  end

  describe "#unique_index_columns" do
    subject { connection.unique_index_columns("courses") }

    before do
      # Setup active_record connection before create database and schema
      connection

      # db:create
      ActiveRecord::Tasks::DatabaseTasks.create(database_config)

      load spec_dir.join("schemas/create_courses.rb")
    end

    it { should eq [["code"]] }
  end
end
