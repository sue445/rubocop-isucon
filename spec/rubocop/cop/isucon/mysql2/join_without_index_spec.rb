# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::JoinWithoutIndex, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/JoinWithoutIndex" => cop_config) }
  let(:cop_config) { {} }

  include_examples :mysql2_cop_common_examples

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

  context "AST Node has NULL JOIN operand" do
    include_context :database_cop do
      let(:schema) do
        %w[
          schemas/create_users.rb
          schemas/create_registrations.rb
          schemas/create_courses.rb
          schemas/create_classes.rb
          schemas/create_submissions.rb
        ]
      end
    end

    it "does not register an offense" do
      # c.f. https://github.com/isucon/isucon11-final/blob/a4ca72f2b4c470d93afe9edd572a2dbd563308fe/webapp/ruby/app.rb#L323-L333
      expect_no_offenses(<<~RUBY)
        totals = db.xquery(
          "SELECT IFNULL(SUM(`submissions`.`score`), 0) AS `total_score`" \\
          " FROM `users`" \\
          " JOIN `registrations` ON `users`.`id` = `registrations`.`user_id`" \\
          " JOIN `courses` ON `registrations`.`course_id` = `courses`.`id`" \\
          " LEFT JOIN `classes` ON `courses`.`id` = `classes`.`course_id`" \\
          " LEFT JOIN `submissions` ON `users`.`id` = `submissions`.`user_id` AND `submissions`.`class_id` = `classes`.`id`" \\
          " WHERE `courses`.`id` = ?" \\
          " GROUP BY `users`.`id`",
          course[:id]
        ).map { |_| _[:total_score] }
      RUBY
    end
  end
end
