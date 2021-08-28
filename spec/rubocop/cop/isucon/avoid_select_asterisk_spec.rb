# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::AvoidSelectAsterisk, :config do
  let(:config) { RuboCop::Config.new }

  context "When using `SELECT *`" do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
                   ^^^^^^^^ Use SELECT with column names. (e.g. `SELECT id, name FROM`)
      RUBY
    end

    context "with substitution" do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          isu = db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? AND `jia_isu_uuid` = ?', jia_user_id, jia_isu_uuid).first
                           ^^^^^^^^ Use SELECT with column names. (e.g. `SELECT id, name FROM`)
        RUBY
      end
    end
  end

  context "When using `SELECT` with column names" do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        db.xquery('SELECT id, jia_isu_uuid, name FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
      RUBY
    end
  end
end
