# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::GdaHelper do
  let(:helper) { RuboCop::Isucon::GdaHelper.new(sql) }

  describe "#table_names" do
    subject { helper.table_names }

    context "single table" do
      let(:sql) do
        # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L118
        <<~SQL
          SELECT * FROM chair WHERE stock > 0 ORDER BY price ASC, id ASC LIMIT 10
        SQL
      end

      it { should contain_exactly("chair") }
    end

    context "multiple tables" do
      let(:sql) do
        <<~SQL
          SELECT
            r.id AS reservation_id,
            r.schedule_id AS reservation_schedule_id,
            r.user_id AS reservation_user_id,
            r.created_at AS reservation_created_at,
            u.id AS user_id,
            u.email AS user_email,
            u.nickname AS user_nickname,
            u.staff AS user_staff,
            u.created_at AS user_created_at
          FROM `reservations` AS r
          INNER JOIN users u ON u.id = r.user_id
          WHERE r.schedule_id = ?
        SQL
      end

      it { should contain_exactly("reservations", "users") }
    end
  end

  describe "#where_clause" do
    context "single condition" do
      let(:sql) do
        # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L118
        <<~SQL
          SELECT * FROM chair WHERE `stock` > 0 ORDER BY price ASC, id ASC LIMIT 10
        SQL
      end

      it "returns response" do
        result = helper.where_clause

        expect(result.count).to eq 1

        expect(result[0].operator).to eq ">"
        expect(result[0].operands).to contain_exactly("stock", "0")
      end
    end

    context "multiple conditions" do
      let(:sql) do
        <<~SQL
          SELECT * FROM chair WHERE id = ? AND stock > 0 AND name IS NOT NULL
        SQL
      end

      it "returns response" do
        result = helper.where_clause

        expect(result.count).to eq 3

        expect(result[0].operator).to eq "="
        expect(result[0].operands).to contain_exactly("id", "'__PRACEHOLDER__'")

        expect(result[1].operator).to eq ">"
        expect(result[1].operands).to contain_exactly("stock", "0")

        expect(result[2].operator).to eq "IS NOT NULL"
        expect(result[2].operands).to contain_exactly("name")
      end
    end
  end

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

  describe "#serialize_statement" do
    subject { helper.serialize_statement }

    let(:sql) do
      # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L118
      <<~SQL
        SELECT * FROM chair WHERE stock > 0 ORDER BY price ASC, id ASC LIMIT 10
      SQL
    end

    it { should be_an_instance_of Hash }
  end
end
