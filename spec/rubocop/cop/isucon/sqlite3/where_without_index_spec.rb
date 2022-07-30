# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Sqlite3::WhereWithoutIndex, :config do
  let(:config) { RuboCop::Config.new("Isucon/Sqlite3/WhereWithoutIndex" => cop_config) }
  let(:cop_config) { {} }

  context "SELECT ~ FROM table1" do
    context "without index" do
      include_context :database_cop do
        let(:schema) { "schemas/create_competition.rb" }
      end

      it "registers an offense" do
        # c.f. https://github.com/isucon/isucon12-qualify/blob/6e4552eca6e3f4b7b799a0573744734399de4dbb/webapp/ruby/app.rb#L434-L438
        expect_offense(<<~RUBY)
          tenant_db.execute('SELECT * FROM competition WHERE tenant_id=?', [t.id]) do |row|
                                                             ^^^^^^^^^^^ This where clause doesn't seem to have an index. (e.g. `CREATE INDEX index_competition_tenant_id ON competition (tenant_id)`)
            comp = CompetitionRow.new(row)
            report = billing_report_by_competition(tenant_db, t.id, comp.id)
            billing_yen += report.billing_yen
          end
        RUBY
      end
    end

    context "with index" do
      include_context :database_cop do
        let(:schema) { %w[schemas/create_competition.rb schemas/add_index_to_competition.rb] }
      end

      it "does not register an offense" do
        # c.f. https://github.com/isucon/isucon12-qualify/blob/6e4552eca6e3f4b7b799a0573744734399de4dbb/webapp/ruby/app.rb#L434-L438
        expect_no_offenses(<<~RUBY)
          tenant_db.execute('SELECT * FROM competition WHERE tenant_id=?', [t.id]) do |row|
            comp = CompetitionRow.new(row)
            report = billing_report_by_competition(tenant_db, t.id, comp.id)
            billing_yen += report.billing_yen
          end
        RUBY
      end
    end

    context "WHERE with id" do
      include_context :database_cop do
        let(:schema) { "schemas/create_competition.rb" }
      end

      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          tenant_db.execute('SELECT * FROM competition WHERE id=?', [t.id]) do |row|
            comp = CompetitionRow.new(row)
            report = billing_report_by_competition(tenant_db, t.id, comp.id)
            billing_yen += report.billing_yen
          end
        RUBY
      end
    end
  end
end
