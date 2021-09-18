# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::GdaNodePatcher do
  let(:patcher) { RuboCop::Isucon::GdaNodePatcher.new }

  def location(begin_pos:, end_pos:, body:)
    RuboCop::Isucon::GdaNodeLocation.new(begin_pos: begin_pos, end_pos: end_pos, body: body)
  end

  describe "#accept" do
    subject { patcher.accept(node, sql) }

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
  end
end
