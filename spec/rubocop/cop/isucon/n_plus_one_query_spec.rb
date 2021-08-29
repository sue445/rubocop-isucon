# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::NPlusOneQuery, :config do
  let(:config) { RuboCop::Config.new }

  context "exists no N+1 query" do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        db.xquery('SELECT * FROM `users` WHERE `id` = ? LIMIT 1', id).first
      RUBY
    end
  end

  context "exists N+1 SELECT query in map" do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        reservations = db.xquery('SELECT * FROM `reservations` WHERE `schedule_id` = ?', schedule_id).map do |reservation|
          reservation[:user] = db.xquery('SELECT * FROM `users` WHERE `id` = ? LIMIT 1', id).first
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This looks like N+1 query.
          reservation
        end
      RUBY
    end
  end

  context "exists N+1 INSERT query in map" do
    it 'registers an offense' do
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
end
