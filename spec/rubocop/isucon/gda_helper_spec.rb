# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::GdaHelper do
  describe ".normalize_sql" do
    subject { RuboCop::Isucon::GdaHelper.normalize_sql(sql) }

    context "contains `" do
      let(:sql) { "SELECT * FROM `chair` WHERE `stock` > 0 ORDER BY `price` ASC, `id` ASC LIMIT 10" }

      it { should eq "SELECT * FROM chair WHERE stock > 0 ORDER BY price ASC, id ASC LIMIT 10" }
    end

    context "contains ?" do
      let(:sql) { "SELECT id FROM categories WHERE parent_id = ?" }

      it { should eq "SELECT id FROM categories WHERE parent_id = '__PRACEHOLDER__'" }
    end
  end
end
