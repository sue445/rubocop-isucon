# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::GDA do
  let(:placeholder) { RuboCop::Isucon::GDA::PRACEHOLDER }

  describe ".normalize_sql" do
    subject { RuboCop::Isucon::GDA.normalize_sql(sql) }

    context "contains `" do
      let(:sql) { "SELECT * FROM `chair` WHERE `stock` > 0 ORDER BY `price` ASC, `id` ASC LIMIT 10" }

      it { should eq "SELECT * FROM  chair  WHERE  stock  > 0 ORDER BY  price  ASC,  id  ASC LIMIT 10" }
      its(:length) { should eq sql.length }
    end

    context "contains ?" do
      let(:sql) { "SELECT id FROM categories WHERE parent_id = ?" }

      it { should eq "SELECT id FROM categories WHERE parent_id = #{placeholder}" }
      its(:length) { should eq sql.length }
    end
  end
end
