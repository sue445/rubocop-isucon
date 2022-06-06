# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Shell::Backtick, :config do
  let(:config) { RuboCop::Config.new }

  context "Command with backtick" do
    it "registers an offense" do
      # https://github.com/catatsuy/private-isu/blob/e6e5faf608756a66b7fc135642999f40dfc665e5/webapp/ruby/app.rb#L80
      expect_offense(<<~RUBY)
        `printf "%s" \#{Shellwords.shellescape(src)} | openssl dgst -sha512 | sed 's/^.*= //'`.strip
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use pure-ruby code instead of external command execution if possible
      RUBY
    end
  end

  context "Command with %x" do
    it "registers an offense" do
      # https://github.com/catatsuy/private-isu/blob/e6e5faf608756a66b7fc135642999f40dfc665e5/webapp/ruby/app.rb#L80
      expect_offense(<<~RUBY)
        %x(printf "%s" \#{Shellwords.shellescape(src)} | openssl dgst -sha512 | sed 's/^.*= //').strip
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use pure-ruby code instead of external command execution if possible
      RUBY
    end
  end
end
