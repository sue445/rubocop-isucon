# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Sinatra::ServeStaticFile, :config do
  let(:config) { RuboCop::Config.new }

  context "when `File.read` is at the end of the block" do
    it "registers an offense" do
      # c.f. https://github.com/isucon/isucon8-final/blob/38c4f6e20388d1c4f1ed393fb75b38d472e44abf/webapp/ruby/app.rb#L55-L58
      expect_offense(<<~RUBY)
        get '/' do
        ^^^^^^^^^^ Serve static files on front server (e.g. nginx) instead of sinatra app
          content_type :html
          File.read(File.join(__dir__, '..', 'public', 'index.html'))
        end
      RUBY
    end
  end

  context "when `File.read` isn't at the end of the block" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        get '/' do
          content_type :html
          File.read(File.join(__dir__, '..', 'public', 'index.html'))
          ""
        end
      RUBY
    end
  end
end
