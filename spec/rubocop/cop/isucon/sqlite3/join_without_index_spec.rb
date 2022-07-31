# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Sqlite3::JoinWithoutIndex, :config do
  let(:config) { RuboCop::Config.new("Isucon/Sqlite3/JoinWithoutIndex" => cop_config) }
  let(:cop_config) { {} }

  context "without index" do
    include_context :database_cop do
      let(:schema) do
        %w[
          schemas/create_courses.rb
          schemas/create_registrations.rb
        ]
      end
    end

    it "registers an offense" do
      expect_offense(<<~RUBY)
        db.execute(
          "SELECT `courses`.*" \\
          " FROM `courses`" \\
          " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^ This join clause doesn't seem to have an index. (e.g. `CREATE INDEX index_registrations_course_id ON registrations (course_id)`)
          " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
          STATUS_CLOSED, user_id,
        )
      RUBY
    end
  end

  context "with index" do
    include_context :database_cop do
      let(:schema) do
        %w[
          schemas/create_courses.rb
          schemas/create_registrations.rb
          schemas/add_index_to_registrations.rb
        ]
      end
    end

    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.execute(
          "SELECT `courses`.*" \\
          " FROM `courses`" \\
          " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
          " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
          STATUS_CLOSED, user_id,
        )
      RUBY
    end
  end
end
