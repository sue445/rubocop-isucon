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

    context "with large SQL" do
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

      it "location is appended" do
        subject

        where_clause =
          node.where_cond.to_a.
            select { |node| node.instance_of?(GDA::Nodes::Operation) && node.operator }

        expect(where_clause.count).to eq 3 # TODO: WIP
      end
    end
  end
end
