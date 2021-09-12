# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::WhereWithoutIndex, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/WhereWithoutIndex" => cop_config) }
  let(:cop_config) { {} }

  context "without index" do
    include_context :database_cop do
      let(:schema) { "schemas/create_isu.rb" }
    end

    it "registers an offense" do
      expect_offense(<<~RUBY)
        db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
                                       ^^^^^ This where clause doesn't seem to have an index. (e.g. 'ALTER TABLE `isu` ADD INDEX `index_jia_user_id` (jia_user_id)')
      RUBY
    end
  end

  context "with index" do
    include_context :database_cop do
      let(:schema) { %w[schemas/create_isu.rb schemas/add_index_to_isu.rb] }
    end

    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
      RUBY
    end
  end

  context "WHERE with id" do
    include_context :database_cop do
      let(:schema) { "schemas/create_isu.rb" }
    end

    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.xquery('SELECT * FROM `isu` WHERE `id` = ? ORDER BY `id` DESC', id)
      RUBY
    end
  end
end
