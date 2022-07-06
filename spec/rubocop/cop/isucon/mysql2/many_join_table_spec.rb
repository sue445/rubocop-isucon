# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::ManyJoinTable, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/ManyJoinTable" => cop_config) }
  let(:cop_config) { { "CountTables" => count_tables } }

  context "total tables >= CountTables" do
    let(:count_tables) { 5 }

    it "registers an offense" do
      # FIXME: duplicate offense messages
      # c.f. https://github.com/isucon/isucon11-final/blob/a4ca72f2b4c470d93afe9edd572a2dbd563308fe/webapp/ruby/app.rb#L323-L333
      expect_offense(<<~RUBY)
        totals = db.xquery(
                 ^^^^^^^^^^ Avoid SQL with lots of JOINs
                 ^^^^^^^^^^ Avoid SQL with lots of JOINs
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

  context "total tables < CountTables" do
    let(:count_tables) { 6 }

    it "registers an offense" do
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
