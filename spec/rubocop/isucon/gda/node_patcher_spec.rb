# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::GDA::NodePatcher do
  let(:patcher) { RuboCop::Isucon::GDA::NodePatcher.new(sql) }

  def location(begin_pos:, end_pos:, body:)
    RuboCop::Isucon::GDA::NodeLocation.new(begin_pos: begin_pos, end_pos: end_pos, body: body)
  end

  describe "#accept" do
    subject { patcher.accept(node) }

    let(:node) { GDA::SQL::Parser.new.parse(sql).ast }

    context "WHERE location" do
      let(:sql) do
        <<~SQL
          SELECT * FROM chair WHERE id = 1 AND stock > 0 AND name IS NOT NULL
        SQL
      end

      it "location is appended" do
        subject

        where_clause =
          node.where_cond.to_a.
          select { |node| node.instance_of?(GDA::Nodes::Operation) && node.operator }

        expect(where_clause.count).to eq 3
        expect(where_clause[0].location).to eq location(begin_pos: 26, end_pos: 32, body: "id = 1")
        expect(where_clause[1].location).to eq location(begin_pos: 37, end_pos: 46, body: "stock > 0")
        expect(where_clause[2].location).to eq location(begin_pos: 51, end_pos: 67, body: "name IS NOT NULL")
      end
    end

    context "ON location" do
      let(:sql) do
        <<~SQL
          SELECT r.*, s.rank AS sheet_rank, s.num AS sheet_num FROM reservations r INNER JOIN sheets s ON s.id = r.sheet_id WHERE r.user_id = 0 ORDER BY IFNULL(r.canceled_at, r.reserved_at) DESC LIMIT 5
        SQL
      end

      it "location is appended" do
        subject

        join_operands = node.from.joins[0].expr.cond.operands

        expect(join_operands.count).to eq 2
        expect(join_operands[0].location).to eq location(begin_pos: 96, end_pos: 100, body: "s.id")
        expect(join_operands[1].location).to eq location(begin_pos: 103, end_pos: 113, body: "r.sheet_id")
      end
    end
  end
end
