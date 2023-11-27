# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Isucon::Mysql2::WhereWithoutIndex, :config do
  let(:config) { RuboCop::Config.new("Isucon/Mysql2/WhereWithoutIndex" => cop_config) }
  let(:cop_config) { {} }

  include_examples :mysql2_cop_common_examples

  context "SELECT ~ FROM table1" do
    context "without index" do
      include_context :database_cop do
        let(:schema) { "schemas/create_isu.rb" }
      end

      context "single line SQL" do
        it "registers an offense" do
          expect_offense(<<~RUBY)
            db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
                                                 ^^^^^^^^^^^^^^^^^ This where clause doesn't seem to have an index. (e.g. `ALTER TABLE isu ADD INDEX index_jia_user_id (jia_user_id)`)
          RUBY
        end
      end

      context "multiple line SQL" do
        context "with `<<~` style heredoc" do
          it "registers an offense" do
            expect_offense(<<~RUBY)
              db.xquery(<<~SQL, jia_user_id)
                SELECT * FROM `isu`
                WHERE `jia_user_id` = ? ORDER BY `id` DESC
                      ^^^^^^^^^^^^^^^^^ This where clause doesn't seem to have an index. (e.g. `ALTER TABLE isu ADD INDEX index_jia_user_id (jia_user_id)`)
              SQL
            RUBY
          end
        end

        context "with `<<-` style heredoc" do
          it "registers an offense" do
            expect_offense(<<~RUBY)
              db.xquery(<<-SQL, jia_user_id)
                SELECT * FROM `isu`
                WHERE `jia_user_id` = ? ORDER BY `id` DESC
                      ^^^^^^^^^^^^^^^^^ This where clause doesn't seem to have an index. (e.g. `ALTER TABLE isu ADD INDEX index_jia_user_id (jia_user_id)`)
              SQL
            RUBY
          end
        end

        context "non heredoc" do
          it "registers an offense" do
            expect_offense(<<~RUBY)
              db.xquery(
                "SELECT * FROM `isu`" \\
                "WHERE `jia_user_id` = ? ORDER BY `id` DESC",
                       ^^^^^^^^^^^^^^^^^ This where clause doesn't seem to have an index. (e.g. `ALTER TABLE isu ADD INDEX index_jia_user_id (jia_user_id)`)
                jia_user_id
              )
            RUBY
          end
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

    context "table isn't found" do
      include_context :database_cop do
        let(:schema) { [] }
      end

      it "does not register an offense and print warning" do
        expect do
          expect_no_offenses(<<~RUBY, "file.rb")
            db.xquery('SELECT * FROM `isu` WHERE `jia_user_id` = ? ORDER BY `id` DESC', jia_user_id)
          RUBY
        end.to output(<<~MSG).to_stderr
          Warning: Could not find table 'isu' (file.rb:1)
        MSG
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
                                                                                                                                                    ^^^^^^^^^^^^^ This where clause doesn't seem to have an index. (e.g. `ALTER TABLE reservations ADD INDEX index_user_id (user_id)`)
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
                                                                                                                                                    ^^^^^^^^^^ This where clause doesn't seem to have an index. (e.g. `ALTER TABLE sheets ADD INDEX index_rank (rank)`)
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

  context "subquery" do
    context "without index" do
      include_context :database_cop do
        let(:schema) do
          %w[
            schemas/create_trade.rb
          ]
        end
      end

      it "registers an offense" do
        # c.f. https://github.com/isucon/isucon8-final/blob/38c4f6e20388d1c4f1ed393fb75b38d472e44abf/webapp/ruby/models/trade.rb#L13-L29
        expect_offense(<<~RUBY)
          db.xquery(<<-EOF, mt).to_a
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
                    ^^^^^^^^^^^^^^^ This where clause doesn't seem to have an index. (e.g. `ALTER TABLE trade ADD INDEX index_created_at (created_at)`)
              GROUP BY t
            ) m
            JOIN trade a ON a.id = m.min_id
            JOIN trade b ON b.id = m.max_id
            ORDER BY m.t
          EOF
        RUBY
      end
    end

    context "with index" do
      include_context :database_cop do
        let(:schema) do
          %w[
            schemas/create_trade.rb
            schemas/add_index_to_trade.rb
          ]
        end
      end

      it "does not register an offense" do
        # c.f. https://github.com/isucon/isucon8-final/blob/38c4f6e20388d1c4f1ed393fb75b38d472e44abf/webapp/ruby/models/trade.rb#L13-L29
        expect_no_offenses(<<~RUBY)
          db.xquery(<<-EOF, mt).to_a
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
          EOF
        RUBY
      end
    end
  end

  context "with block" do
    include_context :database_cop do
      let(:schema) do
        %w[
          schemas/create_livestream_tags.rb
          schemas/create_tags.rb
        ]
      end
    end

    it "registers an offense" do
      # c.f. https://github.com/isucon/isucon13/blob/d33a72acdb4029f1ca53ccbe90ff5f2348c8e5cc/webapp/ruby/app.rb#L105-L121
      expect_offense(<<~RUBY)
        def fill_livestream_response(tx, livestream_model)
          # owner_model = tx.xquery('SELECT * FROM users WHERE id = ?', livestream_model.fetch(:user_id)).first
          # owner = fill_user_response(tx, owner_model)

          tags = tx.xquery('SELECT * FROM livestream_tags WHERE livestream_id = ?', livestream_model.fetch(:id)).map do |livestream_tag_model|
                                                                ^^^^^^^^^^^^^^^^^ This where clause doesn't seem to have an index. (e.g. `ALTER TABLE livestream_tags ADD INDEX index_livestream_id (livestream_id)`)

            tag_model = tx.xquery('SELECT * FROM tags WHERE id = ?', livestream_tag_model.fetch(:tag_id)).first
            {
              id: tag_model.fetch(:id),
              name: tag_model.fetch(:name),
            }
          end

          livestream_model.slice(:id, :title, :description, :playlist_url, :thumbnail_url, :start_at, :end_at).merge(
            owner: owner,
            tags: tags,
          )
        end
      RUBY
    end
  end
end
