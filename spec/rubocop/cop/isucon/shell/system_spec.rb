# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Shell::System, :config do
  let(:config) { RuboCop::Config.new }

  context "Command with system" do
    it "registers an offense" do
      expect_offense(<<~RUBY)
        system("sleep 1")
        ^^^^^^^^^^^^^^^^^ Isucon/Shell/System: Use pure-ruby code instead of external command execution if possible
      RUBY
    end
  end
end
