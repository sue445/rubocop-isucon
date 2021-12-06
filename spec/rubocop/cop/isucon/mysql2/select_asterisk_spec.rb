# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::SelectAsterisk, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/SelectAsterisk" => cop_config) }
  let(:cop_config) { {} }

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

              db.xquery('SELECT `id`, `created_at`, `user_id`, `login`, `ip`, `succeeded` FROM login_log WHERE succeeded = 1 AND user_id = ? ORDER BY id DESC LIMIT 2', current_user['id']).each.last
            end
          RUBY
        end
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

  context "Non DSL" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.query('BEGIN')
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

  context "Unknown AST" do
    it "does not register an offense" do
      # c.f. https://github.com/isucon/isucon11-final/blob/a4ca72f2b4c470d93afe9edd572a2dbd563308fe/webapp/ruby/app.rb#L764-L803
      expect_no_offenses(<<~RUBY)
        query = "SELECT `announcements`.`id`, `courses`.`id` AS `course_id`, `courses`.`name` AS `course_name`, `announcements`.`title`, NOT `unread_announcements`.`is_deleted` AS `unread`" \
          " FROM `announcements`" \
          " JOIN `courses` ON `announcements`.`course_id` = `courses`.`id`" \
          " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \
          " JOIN `unread_announcements` ON `announcements`.`id` = `unread_announcements`.`announcement_id`" \
          " WHERE 1=1"
        args = []

        if params[:course_id] && !params[:course_id].empty?
          query.concat(" AND `announcements`.`course_id` = ?")
          args.push(params[:course_id])
        end

        query.concat(
          " AND `unread_announcements`.`user_id` = ?" \
          " AND `registrations`.`user_id` = ?" \
          " ORDER BY `announcements`.`id` DESC"
        )
        args.push(user_id, user_id)

        page = unless params[:page]
          1
        else
          Integer(params[:page]) rescue halt 400, "Invalid page."
        end
        limit = 20
        offset = limit * (page - 1)

        # limitより多く上限を設定し、実際にlimitより多くレコードが取得できた場合は次のページが存在する
        query.concat " LIMIT \#{(limit+1).to_i} OFFSET \#{offset.to_i}"

        announcements = db.xquery(query, *args).map do |a|
          {
            id: a[:id],
            course_id: a[:course_id],
            course_name: a[:course_name],
            title: a[:title],
            unread: a[:unread] == 1, # cast_booleans doesn't work as it is a computed value
          }
        end
      RUBY
    end
  end
end
