# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Sqlite3::SelectAsterisk, :config do
  let(:config) { RuboCop::Config.new("Isucon/Sqlite3/SelectAsterisk" => cop_config) }
  let(:cop_config) { {} }

  context "When using `SELECT *`" do
    context "without Database config" do
      it "registers an offense and not correct" do
        # c.f. https://github.com/isucon/isucon12-qualify/blob/6e4552eca6e3f4b7b799a0573744734399de4dbb/webapp/ruby/app.rb#L434-L438
        expect_offense(<<~RUBY)
          tenant_db.execute('SELECT * FROM competition WHERE tenant_id=?', [t.id]) do |row|
                                    ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
            comp = CompetitionRow.new(row)
            report = billing_report_by_competition(tenant_db, t.id, comp.id)
            billing_yen += report.billing_yen
          end
        RUBY

        expect_no_corrections
      end
    end

    context "with Database config" do
      include_context :database_cop do
        let(:schema) { "schemas/create_competition.rb" }
      end

      it "registers an offense and correct" do
        expect_offense(<<~RUBY)
          tenant_db.execute('SELECT * FROM competition WHERE tenant_id=?', [t.id]) do |row|
                                    ^ Use SELECT with column names. (e.g. `SELECT id, name FROM table_name`)
            comp = CompetitionRow.new(row)
            report = billing_report_by_competition(tenant_db, t.id, comp.id)
            billing_yen += report.billing_yen
          end
        RUBY

        expect_correction(<<~RUBY)
          # TODO: Remove needless columns if necessary
          tenant_db.execute('SELECT `id`, `tenant_id`, `title`, `finished_at`, `created_at`, `updated_at` FROM competition WHERE tenant_id=?', [t.id]) do |row|
            comp = CompetitionRow.new(row)
            report = billing_report_by_competition(tenant_db, t.id, comp.id)
            billing_yen += report.billing_yen
          end
        RUBY
      end
    end
  end
end
