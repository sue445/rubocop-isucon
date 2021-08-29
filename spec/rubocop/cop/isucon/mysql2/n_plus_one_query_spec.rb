# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::NPlusOneQuery, :config do
  let(:config) { RuboCop::Config.new }

  context "exists no N+1 query" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.xquery('SELECT * FROM `users` WHERE `id` = ? LIMIT 1', id).first
      RUBY
    end
  end

  context "exists N+1 SELECT query in map" do
    context "with xquery" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          reservations = db.xquery('SELECT * FROM `reservations` WHERE `schedule_id` = ?', schedule_id).map do |reservation|
            reservation[:user] = db.xquery('SELECT * FROM `users` WHERE `id` = ? LIMIT 1', id).first
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
            reservation
          end
        RUBY
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
    end
  end
end
