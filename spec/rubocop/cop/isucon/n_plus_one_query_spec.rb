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

  context "exists N+1 query in map" do
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
end
