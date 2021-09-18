# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::GDA::WhereCondition do
  let(:condition) do
    RuboCop::Isucon::GDA::WhereCondition.new(operator: operator, operands: operands)
  end

  describe "#column_operand" do
    subject { condition.column_operand }

    context "WHERE stock > 0" do
      let(:operator) { ">" }
      let(:operands) { %w[stock 0] }

      it { should eq "stock" }
    end

    context "WHERE 0 < stock" do
      let(:operator) { "<" }
      let(:operands) { %w[0 stock] }

      it { should eq "stock" }
    end

    context "WHERE name IS NOT NULL" do
      let(:operator) { "IS NOT NUL" }
      let(:operands) { %w[name] }

      it { should eq "name" }
    end
  end

  describe "#value_operand" do
    subject { condition.value_operand }

    context "WHERE stock > 0" do
      let(:operator) { ">" }
      let(:operands) { %w[stock 0] }

      it { should eq "0" }
    end

    context "WHERE 0 < stock" do
      let(:operator) { "<" }
      let(:operands) { %w[0 stock] }

      it { should eq "0" }
    end

    context "WHERE name IS NOT NULL" do
      let(:operator) { "IS NOT NUL" }
      let(:operands) { %w[name] }

      it { should eq nil }
    end
  end
end
