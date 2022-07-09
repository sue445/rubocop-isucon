# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Sinatra::Logger, :config do
  let(:config) { RuboCop::Config.new }

  context "Exists logger.error" do
    it "registers an offense" do
      # c.f. https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L217
      expect_offense(<<~RUBY)
        logger.error "Search condition not found"
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use `logger`
      RUBY

      expect_correction(<<~RUBY)

      RUBY
    end
  end
end
