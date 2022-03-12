# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Sinatra::RackLogger, :config do
  let(:config) { RuboCop::Config.new }

  context "Exists request.env['rack.logger'].warn" do
    it "registers an offense" do
      # c.f. https://github.com/isucon/isucon11-qualify/blob/1011682c2d5afcc563f4ebf0e4c88a5124f63614/webapp/ruby/app.rb#L627
      expect_offense(<<~RUBY)
        request.env['rack.logger'].warn 'drop post isu condition request'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't use `request.env['rack.logger']`
      RUBY

      expect_correction(<<~RUBY)

      RUBY
    end
  end
end
