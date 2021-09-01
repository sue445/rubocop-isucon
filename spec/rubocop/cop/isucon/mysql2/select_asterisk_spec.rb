# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::SelectAsterisk, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/SelectAsterisk" => cop_config) }
  let(:cop_config) { {} }

  context "When using `SELECT *`" do
    context "with xquery" do
      context "without Database config" do
        it "registers an offense" do
          expect_offense(<<~RUBY)
            db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
                       ^^^^^^^^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
          RUBY

          expect_correction(<<~RUBY)
            db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
          RUBY
        end
      end

      context "with Database config" do
        let(:cop_config) do
          {
            "Database" => {
              "adapter" => "sqlite3",
              "database" => ":memory:",
              "timeout" => 500
            }
          }
        end

        before do
          cop.connection

          # db:create
          ActiveRecord::Tasks::DatabaseTasks.create(cop_config["Database"])

          load schema_dir.join("isu.rb")
        end

        it "registers an offense" do
          expect_offense(<<~RUBY)
            db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
                       ^^^^^^^^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
          RUBY

          expect_correction(<<~RUBY)
            db.xquery('SELECT `id`, `jia_isu_uuid`, `name`, `image`, `character`, `jia_user_id`, `created_at`, `updated_at` FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
          RUBY
        end
      end
    end

    context "with query" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          db.query('SELECT * FROM `isu` WHERE `jia_user_id` = 1 ORDER BY `id` DESC')
                    ^^^^^^^^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
        RUBY
      end
    end

    context "with select" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          event_ids = db.query('SELECT * FROM events ORDER BY id ASC').select(&where).map { |e| e['id'] }
                                ^^^^^^^^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
        RUBY
      end
    end

    context "with substitution" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          isu = db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? AND `jia_isu_uuid` = ?', jia_user_id, jia_isu_uuid).first
                           ^^^^^^^^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
        RUBY
      end
    end

    context "end of method" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          def last_login
            return nil unless current_user

            db.xquery('SELECT * FROM login_log WHERE succeeded = 1 AND user_id = ? ORDER BY id DESC LIMIT 2', current_user['id']).each.last
                       ^^^^^^^^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
          end
        RUBY
      end
    end
  end

  context "When using `SELECT` with column names" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.xquery('SELECT id, jia_isu_uuid, name FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
      RUBY
    end
  end
end
