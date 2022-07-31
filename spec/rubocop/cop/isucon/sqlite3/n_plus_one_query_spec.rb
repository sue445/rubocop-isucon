# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Sqlite3::NPlusOneQuery, :config do
  let(:config) { RuboCop::Config.new("Isucon/Sqlite3/NPlusOneQuery" => cop_config) }
  let(:cop_config) { {} }

  include_context :database_cop do
    let(:schema) do
      %w[
        schemas/create_users.rb
      ]
    end
  end

  context "exists no N+1 query" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.execute('SELECT * FROM `users` WHERE `id` = ? LIMIT 1', [id]).first
      RUBY
    end
  end

  context "exists N+1 INSERT query in map" do
    context "receiver is send_type" do
      it "registers an offense" do
        # c.f. https://github.com/isucon/isucon12-qualify/blob/6e4552eca6e3f4b7b799a0573744734399de4dbb/webapp/ruby/app.rb#L494-L501
        expect_offense(<<~RUBY)
          players = display_names.map do |display_name|
            id = dispense_id

            now = Time.now.to_i
            tenant_db.execute('INSERT INTO player (id, tenant_id, display_name, is_disqualified, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)', [id, v.tenant_id, display_name, 0, now, now])
            ^^^^^^^^^ This looks like N+1 query.
            player = retrieve_player(tenant_db, id)
            player.to_h.slice(:id, :display_name, :is_disqualified)
          end
        RUBY

        expect_no_corrections
      end
    end

    context "receiver is lvar_type" do
      it "registers an offense" do
        # c.f. https://github.com/isucon/isucon12-qualify/blob/6e4552eca6e3f4b7b799a0573744734399de4dbb/webapp/ruby/app.rb#L491-L509
        expect_offense(<<~RUBY)
          connect_to_tenant_db(v.tenant_id) do |tenant_db|
            display_names = params[:display_name]

            players = display_names.map do |display_name|
              id = dispense_id

              now = Time.now.to_i
              tenant_db.execute('INSERT INTO player (id, tenant_id, display_name, is_disqualified, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)', [id, v.tenant_id, display_name, 0, now, now])
              ^^^^^^^^^ This looks like N+1 query.
              player = retrieve_player(tenant_db, id)
              player.to_h.slice(:id, :display_name, :is_disqualified)
            end

            json(
              status: true,
              data: {
                players: players,
              },
            )
          end
        RUBY

        expect_no_corrections
      end
    end
  end

  context "auto corrected code" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        courses = db.execute(
          "SELECT `courses`.*" \\
          " FROM `courses`" \\
          " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
          " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
          [STATUS_CLOSED, user_id],
        ).to_a

        courses.map do |course|
          @users_by_id ||= db.execute('SELECT * FROM `users` WHERE `id` IN (?)', [courses.map { |course| course[:teacher_id] }]).each_with_object({}) { |v, hash| hash[v[:id]] = v }
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
    it "registers an offense and correct" do
      # FIXME: duplicate offense messages
      expect_offense(<<~RUBY)
        courses = db.execute(
          "SELECT `courses`.*" \\
          " FROM `courses`" \\
          " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
          " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
          [STATUS_CLOSED, user_id],
        )

        courses.map do |course|
          teacher = db.execute('SELECT * FROM `users` WHERE `id` = ?', [course[:teacher_id]]).first
                    ^^ This looks like N+1 query.
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
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
        courses = db.execute(
          "SELECT `courses`.*" \\
          " FROM `courses`" \\
          " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \\
          " WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?",
          [STATUS_CLOSED, user_id],
        )

        courses.map do |course|
          @users_by_id ||= db.execute('SELECT * FROM `users` WHERE `id` IN (?)', [courses.map { |course| course[:teacher_id] }]).each_with_object({}) { |v, hash| hash[v[:id]] = v }
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
          teacher = db.execute('SELECT * FROM `users` WHERE `id` = ?', [course["teacher_id"]]).first
                    ^^ This looks like N+1 query.
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
          teacher["name"]
        end
      RUBY

      corrected_code = <<~RUBY
        courses = [{"id" => 1, "teacher_id" => 1}]
        courses.map do |course|
          @users_by_id ||= db.execute('SELECT * FROM `users` WHERE `id` IN (?)', [courses.map { |course| course["teacher_id"] }]).each_with_object({}) { |v, hash| hash[v["id"]] = v }
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
