# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::NPlusOneQuery, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/NPlusOneQuery" => cop_config) }
  let(:cop_config) { {} }

  include_context :database_cop do
    let(:schema) do
      %w[
        schemas/create_users.rb
      ]
    end
  end

  include_examples :mysql2_cop_common_examples

  context "exists no N+1 query" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.xquery('SELECT * FROM `users` WHERE `id` = ? LIMIT 1', id).first
      RUBY
    end
  end

  context "exists N+1 SELECT query in map" do
    context "with xquery" do
      context "with single line SQL" do
        it "registers an offense" do
          expect_offense(<<~RUBY)
            reservations = db.xquery('SELECT * FROM `reservations` WHERE `schedule_id` = ?', schedule_id).map do |reservation|
              reservation[:user] = db.xquery('SELECT * FROM `users` WHERE `id` = ? LIMIT 1', id).first
                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
              reservation
            end
          RUBY

          expect_no_corrections
        end
      end

      context "with multiple line SQL" do
        it "registers an offense" do
          expect_offense(<<~RUBY)
            reservations = db.xquery('SELECT * FROM `reservations` WHERE `schedule_id` = ?', schedule_id).map do |reservation|
              reservation[:user] = db.xquery(<<~SQL, id).first
                                   ^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
                SELECT * FROM `users`
                WHERE `id` = ? LIMIT 1
              SQL
              reservation
            end
          RUBY

          expect_no_corrections
        end
      end
    end

    context "with query" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          reservations = db.query("SELECT * FROM `reservations` WHERE `schedule_id` = 1").map do |reservation|
            reservation[:user] = db.query("SELECT * FROM `users` WHERE `id` = 1 LIMIT 1").first
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            reservation
          end
        RUBY

        expect_no_corrections
      end
    end
  end

  context "exists N+1 INSERT query in map" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        json_params.each do |cond|
          timestamp = Time.at(cond.fetch(:timestamp))
          halt_error 400, 'bad request body' unless valid_condition_format?(cond.fetch(:condition))

          db.xquery(
          ^^ This looks like N+1 query.
            'INSERT INTO `isu_condition` (`jia_isu_uuid`, `timestamp`, `is_sitting`, `condition`, `message`) VALUES (?, ?, ?, ?, ?)',
            jia_isu_uuid,
            timestamp,
            cond.fetch(:is_sitting),
            cond.fetch(:condition),
            cond.fetch(:message),
          )
        end
      RUBY

      expect_no_corrections
    end
  end

  context "exists N+1 any query in map" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        reservations = db.xquery('SELECT * FROM `reservations` WHERE `schedule_id` = ?', schedule_id).map do |reservation|
          sql = 'SELECT * FROM `users` WHERE `id` = ? LIMIT 1'
          reservation[:user] = db.xquery(sql, id).first
                               ^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
          reservation
        end
      RUBY
    end
  end

  context "exists N+1 query in CSV.parse" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        CSV.parse(params[:chairs][:tempfile].read, skip_blanks: true) do |row|
          sql = 'INSERT INTO chair(id, name, description, thumbnail, price, height, width, depth, color, features, kind, popularity, stock) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
          db.xquery(sql, *row.map(&:to_s))
          ^^ This looks like N+1 query.
        end
      RUBY

      expect_no_corrections
    end
  end

  context "auto corrected code" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        courses = db.xquery(
          "SELECT `courses`.*" \\
          " FROM `courses`" \\
          " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
          " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
          STATUS_CLOSED, user_id,
        )

        courses.map do |course|
          @users_by_id ||= db.xquery('SELECT * FROM `users` WHERE `id` IN (?)', courses.map { |course| course[:teacher_id] }).each_with_object({}) { |v, hash| hash[v[:id]] = v }
          teacher = @users_by_id[course[:teacher_id]]
          raise unless teacher

          {
            id: course[:id],
            name: course[:name],
            teacher: teacher[:name],
            period: course[:period],
            day_of_week: course[:day_of_week],
          }
        end
      RUBY
    end
  end

  describe "#perform_autocorrect" do
    context "Hash#[] with symbol key" do
      it "registers an offense and correct" do
        # FIXME: duplicate offense messages
        # c.f. https://github.com/isucon/isucon11-final/blob/667be3ec70c025eadde541e21d5ab1167efa1dd3/webapp/ruby/app.rb#L171-L190
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ?', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_correction(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            @users_by_id ||= db.xquery('SELECT * FROM `users` WHERE `id` IN (?)', courses.map { |course| course[:teacher_id] }).each_with_object({}) { |v, hash| hash[v[:id]] = v }
            teacher = @users_by_id[course[:teacher_id]]
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY
      end
    end

    context "Hash#[] with string key" do
      it "registers an offense and correct" do
        # FIXME: duplicate offense messages
        # c.f. https://github.com/isucon/isucon11-final/blob/667be3ec70c025eadde541e21d5ab1167efa1dd3/webapp/ruby/app.rb#L171-L190
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ?', course["teacher_id"]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_correction(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            @users_by_id ||= db.xquery('SELECT * FROM `users` WHERE `id` IN (?)', courses.map { |course| course["teacher_id"] }).each_with_object({}) { |v, hash| hash[v["id"]] = v }
            teacher = @users_by_id[course["teacher_id"]]
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY
      end
    end

    context "Hash#fetch with symbol key" do
      it "registers an offense and correct" do
        # FIXME: duplicate offense messages
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ?', course.fetch(:teacher_id)).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_correction(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            @users_by_id ||= db.xquery('SELECT * FROM `users` WHERE `id` IN (?)', courses.map { |course| course[:teacher_id] }).each_with_object({}) { |v, hash| hash[v[:id]] = v }
            teacher = @users_by_id[course[:teacher_id]]
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY
      end
    end

    context "Hash#fetch with string key" do
      it "registers an offense and correct" do
        # FIXME: duplicate offense messages
        # c.f. https://github.com/isucon/isucon11-final/blob/667be3ec70c025eadde541e21d5ab1167efa1dd3/webapp/ruby/app.rb#L171-L190
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ?', course.fetch("teacher_id")).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_correction(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            @users_by_id ||= db.xquery('SELECT * FROM `users` WHERE `id` IN (?)', courses.map { |course| course["teacher_id"] }).each_with_object({}) { |v, hash| hash[v["id"]] = v }
            teacher = @users_by_id[course["teacher_id"]]
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY
      end
    end

    context "column in WHERE column isn't PrimaryKey" do
      it "registers an offense and correct" do
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT * FROM `users` WHERE `name` = ?', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_no_corrections
      end
    end

    context "parent_receiver is send_type" do
      it "registers an offense and correct" do
        expect_offense(<<~RUBY)
          courses.map do |course|
            teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ?', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_correction(<<~RUBY)
          courses.map do |course|
            @users_by_id ||= db.xquery('SELECT * FROM `users` WHERE `id` IN (?)', courses.map { |course| course[:teacher_id] }).each_with_object({}) { |v, hash| hash[v[:id]] = v }
            teacher = @users_by_id[course[:teacher_id]]
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY
      end
    end

    context "has LIMIT" do
      it "registers an offense" do
        # FIXME: duplicate offense messages
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ? LIMIT 1', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_no_corrections
      end
    end

    context "has GROUP BY" do
      it "registers an offense" do
        # FIXME: duplicate offense messages
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ? GROUP BY name', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_no_corrections
      end
    end

    context "has C0UNT" do
      it "registers an offense" do
        # FIXME: duplicate offense messages
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT COUNT(*) FROM `users` WHERE `id` = ?', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_no_corrections
      end
    end

    context "has MAX" do
      it "registers an offense" do
        # FIXME: duplicate offense messages
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT MAX(*) FROM `users` WHERE `id` = ?', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_no_corrections
      end
    end

    context "has MIN" do
      it "registers an offense" do
        # FIXME: duplicate offense messages
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT MIN(*) FROM `users` WHERE `id` = ?', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_no_corrections
      end
    end

    context "has SUM" do
      it "registers an offense" do
        # FIXME: duplicate offense messages
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT SUM(*) FROM `users` WHERE `id` = ?', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_no_corrections
      end
    end

    context "has AVG" do
      it "registers an offense" do
        # FIXME: duplicate offense messages
        expect_offense(<<~RUBY)
          courses = db.xquery(
            "SELECT `courses`.*" \\
            " FROM `courses`" \\
            " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
            " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
            STATUS_CLOSED, user_id,
          )

          courses.map do |course|
            teacher = db.xquery('SELECT AVG(*) FROM `users` WHERE `id` = ?', course[:teacher_id]).first
                      ^^ This looks like N+1 query.
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            raise unless teacher

            {
              id: course[:id],
              name: course[:name],
              teacher: teacher[:name],
              period: course[:period],
              day_of_week: course[:day_of_week],
            }
          end
        RUBY

        expect_no_corrections
      end
    end

    context "WHERE with unique index" do
      include_context :database_cop do
        let(:schema) do
          %w[
            schemas/create_courses.rb
          ]
        end
      end

      it "registers an offense and correct" do
        expect_offense(<<~RUBY)
          courses.map do |course|
            c = db.xquery('SELECT * FROM `courses` WHERE `code` = ?', course[:code]).first
                ^^ This looks like N+1 query.
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
          end
        RUBY

        expect_correction(<<~RUBY)
          courses.map do |course|
            @courses_by_code ||= db.xquery('SELECT * FROM `courses` WHERE `code` IN (?)', courses.map { |course| course[:code] }).each_with_object({}) { |v, hash| hash[v[:code]] = v }
            c = @courses_by_code[course[:code]]
          end
        RUBY
      end
    end
  end

  context "with node type: 505" do
    it "does not register an offense" do
      # c.f. https://github.com/isucon/isucon10-final/blob/e858b2588a199f9c7407baacf48b53126b8aeed6/webapp/ruby/app.rb#L96-L111
      expect_no_offenses(<<~RUBY)
        contest = db.query(
          <<~SQL
          SELECT
            *,
            NOW(6) AS `current_time`,
            CASE
              WHEN NOW(6) < `registration_open_at` THEN 'standby'
              WHEN `registration_open_at` <= NOW(6) AND NOW(6) < `contest_starts_at` THEN 'registration'
              WHEN `contest_starts_at` <= NOW(6) AND NOW(6) < `contest_ends_at` THEN 'started'
              WHEN `contest_ends_at` <= NOW(6) THEN 'finished'
              ELSE 'unknown'
            END AS `status`,
            IF(`contest_starts_at` <= NOW(6) AND NOW(6) < `contest_freezes_at`, 1, 0) AS `frozen`
          FROM `contest_config`
          SQL
        ).first
      RUBY
    end
  end

  describe "integration test" do
    include_context :database_cop do
      let(:schema) do
        %w[
          schemas/create_users.rb
        ]
      end
    end

    before do
      create_user(id: 1, name: "user_1")
      create_user(id: 2, name: "user_2")
      create_user(id: 3, name: "user_3")
    end

    let(:db) { DatabaseClient.new }

    it "auto-corrected code is valid" do
      expect_offense(<<~RUBY)
        courses = [{"id" => 1, "teacher_id" => 1}]
        courses.map do |course|
          teacher = db.xquery('SELECT * FROM `users` WHERE `id` = ?', course["teacher_id"]).first
                    ^^ This looks like N+1 query.
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
          teacher["name"]
        end
      RUBY

      corrected_code = <<~RUBY
        courses = [{"id" => 1, "teacher_id" => 1}]
        courses.map do |course|
          @users_by_id ||= db.xquery('SELECT * FROM `users` WHERE `id` IN (?)', courses.map { |course| course["teacher_id"] }).each_with_object({}) { |v, hash| hash[v["id"]] = v }
          teacher = @users_by_id[course["teacher_id"]]
          teacher["name"]
        end
      RUBY

      expect_correction(corrected_code)

      teacher_names = eval(corrected_code) # rubocop:disable Security/Eval
      expect(teacher_names).to eq(["user_1"])
    end
  end

  def create_user(id:, name:)
    current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO users (id, name, created_at, updated_at)
      VALUES(#{id}, '#{name}', '#{current_time}', '#{current_time}')
    SQL
  end
end
