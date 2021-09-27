# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::GDA::Client do
  let(:gda) { RuboCop::Isucon::GDA::Client.new(sql) }

  let(:placeholder) { RuboCop::Isucon::GDA::PRACEHOLDER }

  def join_operand(table_name: nil, column_name: nil, as: nil) # rubocop:disable Naming/MethodParameterName
    RuboCop::Isucon::GDA::JoinOperand.new(table_name: table_name, column_name: column_name, as: as)
  end

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

  describe "#where_conditions" do
    context "single condition" do
      let(:sql) do
        # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L118
        <<~SQL
          SELECT * FROM chair WHERE `stock` > 0 ORDER BY price ASC, id ASC LIMIT 10
        SQL
      end

      it "returns response" do
        result = gda.where_conditions

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
        result = gda.where_conditions

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

  describe "#join_conditions" do
    context "with single join" do
      let(:sql) do
        # https://github.com/isucon/isucon11-final/blob/dd22bc5cea4d8acda14c2596bcfe10e07f19018c/webapp/ruby/app.rb#L172-L175
        <<~SQL
          SELECT `courses`.*
          FROM `courses`
          JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`
          WHERE `courses`.`status` != ? AND `registrations`.`user_id` = ?
        SQL
      end

      it "returns response" do
        result = gda.join_conditions

        expect(result.count).to eq 1

        expect(result[0].operator).to eq "="
        expect(result[0].operands.count).to eq 2
        expect(result[0].operands[0]).to eq join_operand(table_name: "courses", column_name: "id")
        expect(result[0].operands[0].node).not_to be_nil
        expect(result[0].operands[1]).to eq join_operand(table_name: "registrations", column_name: "course_id")
        expect(result[0].operands[1].node).not_to be_nil
      end
    end

    context "multiple joins" do
      # c.f. https://github.com/isucon/isucon8-final/blob/38c4f6e20388d1c4f1ed393fb75b38d472e44abf/webapp/ruby/models/trade.rb#L13-L29
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

      it "returns response" do
        result = gda.join_conditions

        expect(result.count).to eq 2

        expect(result[0].operator).to eq "="
        expect(result[0].operands.count).to eq 2
        expect(result[0].operands[0]).to eq join_operand(table_name: "trade", column_name: "id", as: "a")
        expect(result[0].operands[0].node).not_to be_nil
        expect(result[0].operands[1]).to eq join_operand(as: "m", column_name: "min_id")
        expect(result[0].operands[1].node).not_to be_nil

        expect(result[1].operator).to eq "="
        expect(result[1].operands.count).to eq 2
        expect(result[1].operands[0]).to eq join_operand(table_name: "trade", column_name: "id", as: "b")
        expect(result[0].operands[0].node).not_to be_nil
        expect(result[1].operands[1]).to eq join_operand(as: "m", column_name: "max_id")
        expect(result[0].operands[1].node).not_to be_nil
      end
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
