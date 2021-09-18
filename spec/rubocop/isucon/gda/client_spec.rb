# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::GDA::Client do
  let(:gda) { RuboCop::Isucon::GDA::Client.new(sql) }

  let(:placeholder) { RuboCop::Isucon::GDA::PRACEHOLDER }

  describe "#table_names" do
    subject { gda.table_names }

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
        result = gda.where_clause

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
        result = gda.where_clause

        expect(result.count).to eq 3

        expect(result[0].operator).to eq "="
        expect(result[0].operands).to contain_exactly("id", placeholder)

        expect(result[1].operator).to eq ">"
        expect(result[1].operands).to contain_exactly("stock", "0")

        expect(result[2].operator).to eq "IS NOT NULL"
        expect(result[2].operands).to contain_exactly("name")
      end
    end
  end

  describe ".normalize_sql" do
    subject { RuboCop::Isucon::GDA::Client.normalize_sql(sql) }

    context "contains `" do
      let(:sql) { "SELECT * FROM `chair` WHERE `stock` > 0 ORDER BY `price` ASC, `id` ASC LIMIT 10" }

      it { should eq "SELECT * FROM  chair  WHERE  stock  > 0 ORDER BY  price  ASC,  id  ASC LIMIT 10" }
    end

    context "contains ?" do
      let(:sql) { "SELECT id FROM categories WHERE parent_id = ?" }

      it { should eq "SELECT id FROM categories WHERE parent_id = #{placeholder}" }
    end
  end

  describe "#serialize_statement" do
    subject { gda.serialize_statement }

    let(:sql) do
      # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L118
      <<~SQL
        SELECT * FROM chair WHERE stock > 0 ORDER BY price ASC, id ASC LIMIT 10
      SQL
    end

    it { should be_an_instance_of Hash }
  end

  describe "#visit_subquery_recursive" do
    let(:sql) do
      <<~SQL
        SELECT m.t AS time, a.price AS open, b.price AS close, m.h AS high, m.l AS low
        FROM (
          SELECT
            STR_TO_DATE(DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s'), '%Y-%m-%d %H:%i:%s') AS t,
            MIN(id) AS min_id,
            MAX(id) AS max_id,
            MAX(price) AS h,
            MIN(price) AS l
          FROM trade
          WHERE created_at >= ?
          GROUP BY t
        ) m
        JOIN trade a ON a.id = m.min_id
        JOIN trade b ON b.id = m.max_id
        ORDER BY m.t
      SQL
    end

    it { expect { |b| gda.visit_subquery_recursive(&b) }.to yield_with_args(RuboCop::Isucon::GDA::Client) }
    it { expect { |b| gda.visit_subquery_recursive(&b) }.to yield_control.at_least(1).times }
  end

  describe "#visit_all" do
    let(:sql) do
      <<~SQL
        SELECT m.t AS time, a.price AS open, b.price AS close, m.h AS high, m.l AS low
        FROM (
          SELECT
            STR_TO_DATE(DATE_FORMAT(created_at, '%Y-%m-%d %H:%i:%s'), '%Y-%m-%d %H:%i:%s') AS t,
            MIN(id) AS min_id,
            MAX(id) AS max_id,
            MAX(price) AS h,
            MIN(price) AS l
          FROM trade
          WHERE created_at >= ?
          GROUP BY t
        ) m
        JOIN trade a ON a.id = m.min_id
        JOIN trade b ON b.id = m.max_id
        ORDER BY m.t
      SQL
    end

    it { expect { |b| gda.visit_all(&b) }.to yield_successive_args(RuboCop::Isucon::GDA::Client, RuboCop::Isucon::GDA::Client) }
    it { expect { |b| gda.visit_all(&b) }.to yield_control.at_least(2).times }
  end
end
