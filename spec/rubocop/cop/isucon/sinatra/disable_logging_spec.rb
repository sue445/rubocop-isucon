# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Sinatra::DisableLogging, :config do
  let(:config) { RuboCop::Config.new }

  context "logging is enabled" do
    context "Found Sinatra::Base" do
      it "registers an offense" do
        expect_offense(<<~RUBY)
          class App < Sinatra::Base
            enable :logging
            ^^^^^^^^^^^^^^^ Disable sinatra logging.
          end
        RUBY

        expect_correction(<<~RUBY)
          class App < Sinatra::Base
            disable :logging
          end
        RUBY
      end
    end

    context "Not found Sinatra::Base" do
      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          enable :logging
        RUBY
      end
    end
  end

  context "logging is disabled" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class App < Sinatra::Base
          disable :logging
        end
      RUBY
    end
  end

  context "logging is none" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class App < Sinatra::Base
        end
      RUBY
    end
  end
end
