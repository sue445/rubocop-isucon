# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::JoinWithoutIndex, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/JoinWithoutIndex" => cop_config) }
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
        courses = db.xquery(
          "SELECT `courses`.*" \\
          " FROM `courses`" \\
          " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^ This join clause doesn't seem to have an index. (e.g. 'ALTER TABLE `registrations` ADD INDEX `index_course_id` (course_id)')
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
        courses = db.xquery(
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
