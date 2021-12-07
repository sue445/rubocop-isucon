# frozen_string_literal: true

RSpec.shared_examples :mysql2_cop_common_examples do
  context "db.xquery with embed variable string" do
    it "does not register an offense" do
      # c.f. https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L244
      expect_no_offenses(<<~RUBY)
        count = db.xquery("\#{count_prefix}\#{search_condition}", query_params).first[:count]
      RUBY
    end
  end
end
