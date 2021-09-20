# frozen_string_literal: true

RSpec.describe GDA::Nodes::Node do
  describe "#inspect" do
    subject { node.inspect }

    let(:node) { RuboCop::Isucon::GDA::Client.new(sql).ast }
    let(:sql) { "SELECT * FROM users" }

    it { should match(/#<GDA::Nodes::Select:0x[0-9a-f]{16}>$/) }
  end
end
