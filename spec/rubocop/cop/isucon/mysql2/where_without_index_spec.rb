# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::WhereWithoutIndex, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/WhereWithoutIndex" => cop_config) }
  let(:cop_config) { {} }

  context "SELECT ~ FROM table1" do
    context "without index" do
      include_context :database_cop do
        let(:schema) { "schemas/create_isu.rb" }
      end

      context "single line SQL" do
        it "registers an offense" do
          expect_offense(<<~RUBY)
            db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
                                           ^^^^^ This where clause doesn't seem to have an index. (e.g. 'ALTER TABLE `isu` ADD INDEX `index_jia_user_id` (jia_user_id)')
          RUBY
        end
      end

      context "multiple line SQL" do
        it "registers an offense" do
          expect_offense(<<~RUBY)
            db.xquery(<<~SQL, jia_user_id)
              SELECT * FROM `isu`
              WHERE `jia_user_id` = ? ORDER BY `id` DESC
              ^^^^^ This where clause doesn't seem to have an index. (e.g. 'ALTER TABLE `isu` ADD INDEX `index_jia_user_id` (jia_user_id)')
            SQL
          RUBY
        end
      end
    end

    context "with index" do
      include_context :database_cop do
        let(:schema) { %w[schemas/create_isu.rb schemas/add_index_to_isu.rb] }
      end

      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
        RUBY
      end
    end

    context "WHERE with id" do
      include_context :database_cop do
        let(:schema) { "schemas/create_isu.rb" }
      end

      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          db.xquery('SELECT * FROM `isu` WHERE `id` = ? ORDER BY `id` DESC', id)
        RUBY
      end
    end
  end

  context "SELECT ~ FROM table1 JOIN table2" do
    context "without index in main table" do
      include_context :database_cop do
        let(:schema) do
          %w[
            schemas/create_reservations.rb
            schemas/create_sheets.rb
            schemas/add_index_to_sheets.rb
          ]
        end
      end

      it "registers an offense" do
        # c.f. https://github.com/isucon/isucon8-qualify/blob/fb07e6dc4790d8203d87027d5625a1fc055c2ed6/webapp/ruby/lib/torb/web.rb#L211
        expect_offense(<<~RUBY)
          rows = db.xquery('SELECT r.*, s.rank AS sheet_rank, s.num AS sheet_num FROM reservations r INNER JOIN sheets s ON s.id = r.sheet_id WHERE r.user_id = ? ORDER BY IFNULL(r.canceled_at, r.reserved_at) DESC LIMIT 5', user['id'])
                                                                                                                                              ^^^^^ This where clause doesn't seem to have an index. (e.g. 'ALTER TABLE `reservations` ADD INDEX `index_user_id` (user_id)')
        RUBY
      end
    end

    context "without index in join table" do
      include_context :database_cop do
        let(:schema) do
          %w[
            schemas/create_reservations.rb
            schemas/create_sheets.rb
            schemas/add_index_to_reservations.rb
          ]
        end
      end

      it "registers an offense" do
        expect_offense(<<~RUBY)
          rows = db.xquery('SELECT r.*, s.rank AS sheet_rank, s.num AS sheet_num FROM reservations r INNER JOIN sheets s ON s.id = r.sheet_id WHERE s.rank = ? ORDER BY IFNULL(r.canceled_at, r.reserved_at) DESC LIMIT 5', user['id'])
                                                                                                                                              ^^^^^ This where clause doesn't seem to have an index. (e.g. 'ALTER TABLE `sheets` ADD INDEX `index_rank` (rank)')
        RUBY
      end
    end

    context "with index both main table and join table" do
      include_context :database_cop do
        let(:schema) do
          %w[
            schemas/create_reservations.rb
            schemas/create_sheets.rb
            schemas/add_index_to_reservations.rb
            schemas/add_index_to_sheets.rb
          ]
        end
      end

      it "does not register an offense" do
        expect_no_offenses(<<~RUBY)
          rows = db.xquery('SELECT r.*, s.rank AS sheet_rank, s.num AS sheet_num FROM reservations r INNER JOIN sheets s ON s.id = r.sheet_id WHERE  r.user_id = ? AND s.rank = ? ORDER BY IFNULL(r.canceled_at, r.reserved_at) DESC LIMIT 5', user['id'])
        RUBY
      end
    end
  end
end
