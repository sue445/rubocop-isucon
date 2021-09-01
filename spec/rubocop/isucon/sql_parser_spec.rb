# frozen_string_literal: true

RSpec.describe RuboCop::Isucon::SqlParser do
  describe ".parse_table" do
    subject { RuboCop::Isucon::SqlParser.parse_tables(sql) }

    context "SELECT" do
      context "plain" do
        let(:sql) do
          # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L118
          <<~SQL
            SELECT * FROM chair WHERE stock > 0 ORDER BY price ASC, id ASC LIMIT 10
          SQL
        end

        it { should contain_exactly("chair") }
      end

      context "with quote" do
        let(:sql) do
          # https://github.com/isucon/isucon9-qualify/blob/34b3e785ebdd97d5c39a1263cbf56d1ae5e3ef91/webapp/ruby/lib/isucari/web.rb#L225
          <<~SQL
            SELECT id FROM `categories` WHERE parent_id = ?
          SQL
        end

        it { should contain_exactly("categories") }
      end

      context "with multiline" do
        let(:sql) do
          # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L118
          <<~SQL
            SELECT * FROM
            chair
            WHERE stock > 0 ORDER BY price ASC, id ASC LIMIT 10
          SQL
        end

        it { should contain_exactly("chair") }
      end

      context "with FOR UPDATE" do
        let(:sql) do
          # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L304
          <<~SQL
            SELECT * FROM chair WHERE id = ? AND stock > 0 FOR UPDATE
          SQL
        end

        it { should contain_exactly("chair") }
      end

      context "with sub query" do
        let(:sql) do
          <<~SQL
            SELECT DISTINCT id
             , name, description, thumbnail, address, latitude, longitude, rent, door_height, door_width, features, popularity, popularity_desc
            FROM (
              SELECT * FROM estate WHERE (door_width >= ? AND door_height >= ?)
              UNION ALL
              SELECT * FROM estate WHERE (door_width >= ? AND door_height >= ?)
              UNION ALL
              SELECT * FROM estate WHERE (door_width >= ? AND door_height >= ?)
              UNION ALL
              SELECT * FROM estate WHERE (door_width >= ? AND door_height >= ?)
              UNION ALL
              SELECT * FROM estate WHERE (door_width >= ? AND door_height >= ?)
              UNION ALL
              SELECT * FROM estate WHERE (door_width >= ? AND door_height >= ?)
            ) AS estate_all
            ORDER BY popularity_desc ASC, id ASC LIMIT 20
          SQL
        end

        it { should contain_exactly("estate") }
      end

      describe "multiple tables (JOIN)" do
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

      describe "multiple tables (in sub query)" do
        let(:sql) do
          <<~SQL
            SELECT
              s.id AS id,
              s.title AS title,
              s.capacity AS capacity,
              s.created_at AS created_at,
              IFNULL(r.reserved, 0) AS reserved
            FROM `schedules` AS s
            LEFT JOIN (
              SELECT
                schedule_id,
                COUNT(*) AS reserved
              FROM reservations
              GROUP BY schedule_id
            ) r ON s.id = r.schedule_id
            ORDER BY s.id DESC
          SQL
        end

        it { should contain_exactly("reservations", "schedules") }
      end

      describe "multiple tables (Too heavy SQL)" do
        let(:sql) do
          # c.f. https://github.com/isucon/isucon10-final/blob/e858b2588a199f9c7407baacf48b53126b8aeed6/webapp/ruby/app.rb#L250-L318
          <<~SQL
            SELECT
              `teams`.`id` AS `id`,
              `teams`.`name` AS `name`,
              `teams`.`leader_id` AS `leader_id`,
              `teams`.`withdrawn` AS `withdrawn`,
              `team_student_flags`.`student` AS `student`,
              (`best_score_jobs`.`score_raw` - `best_score_jobs`.`score_deduction`) AS `best_score`,
              `best_score_jobs`.`started_at` AS `best_score_started_at`,
              `best_score_jobs`.`finished_at` AS `best_score_marked_at`,
              (`latest_score_jobs`.`score_raw` - `latest_score_jobs`.`score_deduction`) AS `latest_score`,
              `latest_score_jobs`.`started_at` AS `latest_score_started_at`,
              `latest_score_jobs`.`finished_at` AS `latest_score_marked_at`,
              `latest_score_job_ids`.`finish_count` AS `finish_count`
            FROM
              `teams`
              -- latest scores
              LEFT JOIN (
                SELECT
                  MAX(`id`) AS `id`,
                  `team_id`,
                  COUNT(*) AS `finish_count`
                FROM
                  `benchmark_jobs`
                WHERE
                  `finished_at` IS NOT NULL
                  -- score freeze
                  AND (`team_id` = ? OR (`team_id` != ? AND (? = TRUE OR `finished_at` < ?)))
                GROUP BY
                  `team_id`
              ) `latest_score_job_ids` ON `latest_score_job_ids`.`team_id` = `teams`.`id`
              LEFT JOIN `benchmark_jobs` `latest_score_jobs` ON `latest_score_job_ids`.`id` = `latest_score_jobs`.`id`
              -- best scores
              LEFT JOIN (
                SELECT
                  MAX(`j`.`id`) AS `id`,
                  `j`.`team_id` AS `team_id`
                FROM
                  (
                    SELECT
                      `team_id`,
                      MAX(`score_raw` - `score_deduction`) AS `score`
                    FROM
                      `benchmark_jobs`
                    WHERE
                      `finished_at` IS NOT NULL
                      -- score freeze
                      AND (`team_id` = ? OR (`team_id` != ? AND (? = TRUE OR `finished_at` < ?)))
                    GROUP BY
                      `team_id`
                  ) `best_scores`
                  LEFT JOIN `benchmark_jobs` `j` ON (`j`.`score_raw` - `j`.`score_deduction`) = `best_scores`.`score`
                    AND `j`.`team_id` = `best_scores`.`team_id`
                GROUP BY
                  `j`.`team_id`
              ) `best_score_job_ids` ON `best_score_job_ids`.`team_id` = `teams`.`id`
              LEFT JOIN `benchmark_jobs` `best_score_jobs` ON `best_score_jobs`.`id` = `best_score_job_ids`.`id`
              -- check student teams
              LEFT JOIN (
                SELECT
                  `team_id`,
                  (SUM(`student`) = COUNT(*)) AS `student`
                FROM
                  `contestants`
                GROUP BY
                  `contestants`.`team_id`
              ) `team_student_flags` ON `team_student_flags`.`team_id` = `teams`.`id`
            ORDER BY
              `latest_score` DESC,
              `latest_score_marked_at` ASC
          SQL
        end

        it { should contain_exactly("benchmark_jobs", "contestants", "teams") }
      end
    end

    context "INSERT" do
      context "Simple" do
        # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L281
        let(:sql) do
          <<~SQL
            INSERT INTO chair(id, name, description, thumbnail, price, height, width, depth, color, features, kind, popularity, stock) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          SQL
        end

        it { should contain_exactly("chair") }
      end

      context "ON DUPLICATE KEY UPDATE" do
        # https://github.com/isucon/isucon6-qualify/blob/ba21fa19573deba630f34ebe470141dff6a67273/webapp/ruby/lib/isuda/web.rb#L220-L223
        let(:sql) do
          <<~SQL
            INSERT INTO entry (author_id, keyword, description, created_at, updated_at)
            VALUES (?, ?, ?, NOW(), NOW())
            ON DUPLICATE KEY UPDATE
            author_id = ?, keyword = ?, description = ?, updated_at = NOW()
          SQL
        end

        it { should contain_exactly("entry") }
      end
    end

    context "UPDATE" do
      # https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L309
      let(:sql) do
        <<~SQL
          UPDATE chair SET stock = stock - 1 WHERE id = ?
        SQL
      end

      it { should contain_exactly("chair") }
    end

    context "other" do
      let(:sql) do
        <<~SQL
          USE isucon
        SQL
      end

      it { should be_empty }
    end
  end
end
