# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::SelectAsterisk, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/SelectAsterisk" => cop_config) }
  let(:cop_config) { {} }

  include_examples :mysql2_cop_common_examples

  context "When using `SELECT *`" do
    context "with xquery" do
      context "without Database config" do
        it "registers an offense and not correct" do
          expect_offense(<<~RUBY)
            db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
                              ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
          RUBY

          expect_no_corrections
        end
      end

      context "with Database config" do
        include_context :database_cop do
          let(:schema) { "schemas/create_isu.rb" }
        end

        context "single line SQL" do
          it "registers an offense and correct" do
            expect_offense(<<~RUBY)
              db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
                                ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
            RUBY

            expect_correction(<<~RUBY)
              # TODO: Remove needless columns if necessary
              db.xquery('SELECT `id`, `jia_isu_uuid`, `name`, `image`, `character`, `jia_user_id`, `created_at`, `updated_at` FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
            RUBY
          end
        end

        context "multiple line SQL (heredoc)" do
          it "registers an offense and correct" do
            expect_offense(<<~RUBY)
              db.xquery(<<~SQL, jia_user_id)
                SELECT * FROM `isu`
                       ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
                WHERE `jia_user_id` = ?
                ORDER BY `id` DESC
              SQL
            RUBY

            expect_correction(<<~RUBY)
              # TODO: Remove needless columns if necessary
              db.xquery(<<~SQL, jia_user_id)
                SELECT `id`, `jia_isu_uuid`, `name`, `image`, `character`, `jia_user_id`, `created_at`, `updated_at` FROM `isu`
                WHERE `jia_user_id` = ?
                ORDER BY `id` DESC
              SQL
            RUBY
          end
        end

        context "multiple line SQL (escape is added at the end of the line)" do
          include_context :database_cop do
            let(:schema) { "schemas/create_classes.rb" }
          end

          it "registers an offense and correct" do
            # https://github.com/isucon/isucon11-final/blob/dd22bc5cea4d8acda14c2596bcfe10e07f19018c/webapp/ruby/app.rb#L288-L294
            expect_offense(<<~RUBY)
              classes = db.xquery(
                "SELECT *" \\
                        ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
                " FROM `classes`" \\
                " WHERE `course_id` = ?" \\
                " ORDER BY `part` DESC",
                course[:id]
              )
            RUBY

            expect_correction(<<~RUBY)
              # TODO: Remove needless columns if necessary
              classes = db.xquery(
                "SELECT `id`, `course_id`, `part`, `title`, `description`, `submission_closed`" \\
                " FROM `classes`" \\
                " WHERE `course_id` = ?" \\
                " ORDER BY `part` DESC",
                course[:id]
              )
            RUBY
          end
        end
      end
    end

    context "with query" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          db.query('SELECT * FROM `isu` WHERE `jia_user_id` = 1 ORDER BY `id` DESC')
                           ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
        RUBY
      end
    end

    context "with select" do
      context "with Database config" do
        include_context :database_cop do
          let(:schema) { "schemas/create_events.rb" }
        end

        it "registers an offense and not correct" do
          expect_offense(<<~RUBY)
            event_ids = db.query('SELECT * FROM events ORDER BY id ASC').select(&where).map { |e| e['id'] }
                                         ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
          RUBY

          expect_correction(<<~RUBY)
            # TODO: Remove needless columns if necessary
            event_ids = db.query('SELECT `id`, `title`, `public_fg`, `closed_fg`, `price`, `created_at`, `updated_at` FROM events ORDER BY id ASC').select(&where).map { |e| e['id'] }
          RUBY
        end
      end

      context "without Database config" do
        it "registers an offense and correct" do
          expect_offense(<<~RUBY)
            event_ids = db.query('SELECT * FROM events ORDER BY id ASC').select(&where).map { |e| e['id'] }
                                         ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
          RUBY

          expect_no_corrections
        end
      end
    end

    context "with substitution" do
      context "without Database config" do
        it "registers an offense and not correct" do
          expect_offense(<<~RUBY)
            isu = db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? AND `jia_isu_uuid` = ?', jia_user_id, jia_isu_uuid).first
                                    ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
          RUBY

          expect_no_corrections
        end
      end

      context "with Database config" do
        include_context :database_cop do
          let(:schema) { "schemas/create_isu.rb" }
        end

        it "registers an offense and correct" do
          expect_offense(<<~RUBY)
            isu = db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? AND `jia_isu_uuid` = ?', jia_user_id, jia_isu_uuid).first
                                    ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
          RUBY

          expect_correction(<<~RUBY)
            # TODO: Remove needless columns if necessary
            isu = db.xquery('SELECT `id`, `jia_isu_uuid`, `name`, `image`, `character`, `jia_user_id`, `created_at`, `updated_at` FROM `isu` WHERE `jia_user_id` = ? AND `jia_isu_uuid` = ?', jia_user_id, jia_isu_uuid).first
          RUBY
        end
      end
    end

    context "end of method" do
      context "without Database config" do
        it "registers an offense and not correct" do
          expect_offense(<<~RUBY)
            def last_login
              return nil unless current_user

              db.xquery('SELECT * FROM login_log WHERE succeeded = 1 AND user_id = ? ORDER BY id DESC LIMIT 2', current_user['id']).each.last
                                ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
            end
          RUBY

          expect_no_corrections
        end
      end

      context "with Database config" do
        include_context :database_cop do
          let(:schema) { "schemas/create_login_log.rb" }
        end

        it "registers an offense and correct" do
          expect_offense(<<~RUBY)
            def last_login
              return nil unless current_user

              db.xquery('SELECT * FROM login_log WHERE succeeded = 1 AND user_id = ? ORDER BY id DESC LIMIT 2', current_user['id']).each.last
                                ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
            end
          RUBY

          expect_correction(<<~RUBY)
            def last_login
              return nil unless current_user

              # TODO: Remove needless columns if necessary
              db.xquery('SELECT `id`, `created_at`, `user_id`, `login`, `ip`, `succeeded` FROM login_log WHERE succeeded = 1 AND user_id = ? ORDER BY id DESC LIMIT 2', current_user['id']).each.last
            end
          RUBY
        end
      end
    end
  end

  context "With using `SELECT table_name.*`" do
    include_context :database_cop do
      let(:schema) do
        %w[
          schemas/create_users.rb
          schemas/create_registrations.rb
        ]
      end
    end

    it "registers an offense and correct" do
      # c.f. https://github.com/isucon/isucon11-final/blob/a4ca72f2b4c470d93afe9edd572a2dbd563308fe/webapp/ruby/app.rb#L869-L874
      expect_offense(<<~RUBY)
        targets = db.xquery(
          "SELECT `users`.* FROM `users`" \\
                  ^^^^^^^^^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
          " JOIN `registrations` ON `users`.`id` = `registrations`.`user_id`" \\
          " WHERE `registrations`.`course_id` = ?",
          json_params[:course_id],
        )
      RUBY

      expect_correction(<<~RUBY)
        # TODO: Remove needless columns if necessary
        targets = db.xquery(
          "SELECT `users`.`id`, `users`.`name`, `users`.`created_at`, `users`.`updated_at` FROM `users`" \\
          " JOIN `registrations` ON `users`.`id` = `registrations`.`user_id`" \\
          " WHERE `registrations`.`course_id` = ?",
          json_params[:course_id],
        )
      RUBY
    end
  end

  context "When using `SELECT` with column names" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.xquery('SELECT id, jia_isu_uuid, name FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
      RUBY
    end
  end

  context "Non SELECT query" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.xquery("UPDATE `courses` SET `status` = ? WHERE `id` = ?", json_params[:status], params[:course_id])
      RUBY
    end
  end
end
