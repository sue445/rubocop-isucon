# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::PrepareExecute, :config do
  let(:config) { RuboCop::Config.new }

  context "db.prepare.execute" do
    context "with 1 arg" do
      it "registers an offense and correct" do
        # c.f. https://github.com/catatsuy/private-isu/blob/e6e5faf608756a66b7fc135642999f40dfc665e5/webapp/ruby/app.rb#L93-L95
        expect_offense(<<~RUBY)
          db.prepare('SELECT * FROM `users` WHERE `id` = ?').execute(
             ^^^^^^^ Use `db.xquery` instead of `db.prepare`
            session[:user][:id]
          ).first
        RUBY

        expect_correction(<<~RUBY)
          db.xquery('SELECT * FROM `users` WHERE `id` = ?', session[:user][:id]).first
        RUBY
      end
    end

    context "with multiple args" do
      it "registers an offense and correct" do
        # c.f. https://github.com/catatsuy/private-isu/blob/e6e5faf608756a66b7fc135642999f40dfc665e5/webapp/ruby/app.rb#L326-L331
        expect_offense(<<~RUBY)
          db.prepare(query).execute(
             ^^^^^^^ Use `db.xquery` instead of `db.prepare`
            me[:id],
            mime,
            params["file"][:tempfile].read,
            params["body"],
          )
        RUBY

        expect_correction(<<~RUBY)
          db.xquery(query,
            me[:id],
            mime,
            params["file"][:tempfile].read,
            params["body"],
          )
        RUBY
      end
    end
  end

  context "db.prepare" do
    it "registers an offense" do
      # c.f. https://github.com/isucon/isucon7-qualify/blob/18fd704fdf4a6b58fcd294a848c031c63cba8143/webapp/ruby/app.rb#L88
      expect_offense(<<~RUBY)
        statement = db.prepare('SELECT * FROM user WHERE name = ?')
                       ^^^^^^^ Use `db.xquery` instead of `db.prepare`
      RUBY

      expect_no_corrections
    end
  end
end
