# frozen_string_literal: true

module RuboCop
  module Cop
    module Isucon
      module Mysql2
        # Check if SQL contains many JOINs
        #
        # @example CountJoins: 3 (default)
        #   # bad
        #   totals = db.xquery(
        #     "SELECT IFNULL(SUM(`submissions`.`score`), 0) AS `total_score`" \
        #     " FROM `users`" \
        #     " JOIN `registrations` ON `users`.`id` = `registrations`.`user_id`" \
        #     " JOIN `courses` ON `registrations`.`course_id` = `courses`.`id`" \
        #     " LEFT JOIN `classes` ON `courses`.`id` = `classes`.`course_id`" \
        #     " LEFT JOIN `submissions` ON `users`.`id` = `submissions`.`user_id` AND `submissions`.`class_id` = `classes`.`id`" \
        #     " WHERE `courses`.`id` = ?" \
        #     " GROUP BY `users`.`id`",
        #     course[:id]
        #   ).map { |_| _[:total_score] }
        #
        #   # good
        #   registration_users_count =
        #     db.xquery("SELECT COUNT(`user_id`) AS cnt FROM `registrations` WHERE `course_id` = ?", course[:id]).first[:cnt]
        #
        #   totals = db.xquery(<<~SQL, course[:id]).map { |_| _[:total_score] }
        #     SELECT IFNULL(SUM(`submissions`.`score`), 0) AS `total_score`
        #     FROM `submissions`
        #     JOIN `classes` ON `classes`.`id` = `submissions`.`class_id`
        #     WHERE `classes`.`course_id` = ?
        #     GROUP BY `submissions`.`user_id`
        #   SQL
        #
        #   if totals.count < registration_users_count
        #     no_submissions_count = registration_users_count - totals.count
        #     totals += [0] * no_submissions_count
        #   end
        #
        # @example CountJoins: 6
        #   # good
        #   totals = db.xquery(
        #     "SELECT IFNULL(SUM(`submissions`.`score`), 0) AS `total_score`" \
        #     " FROM `users`" \
        #     " JOIN `registrations` ON `users`.`id` = `registrations`.`user_id`" \
        #     " JOIN `courses` ON `registrations`.`course_id` = `courses`.`id`" \
        #     " LEFT JOIN `classes` ON `courses`.`id` = `classes`.`course_id`" \
        #     " LEFT JOIN `submissions` ON `users`.`id` = `submissions`.`user_id` AND `submissions`.`class_id` = `classes`.`id`" \
        #     " WHERE `courses`.`id` = ?" \
        #     " GROUP BY `users`.`id`",
        #     course[:id]
        #   ).map { |_| _[:total_score] }
        #
        class ManyJoinTable < Base
          include Mixin::Mysql2XqueryMethods

          MSG = "Avoid SQL with lots of JOINs"

          # @param node [RuboCop::AST::Node]
          def on_send(node)
            with_xquery(node) do |_, root_gda|
              check_and_register_offence(root_gda: root_gda, node: node)
            end
          end

          private

          # @param root_gda [RuboCop::Isucon::GDA::Client]
          # @param node [RuboCop::AST::Node]
          def check_and_register_offence(root_gda:, node:)
            return unless root_gda

            root_gda.visit_all do |gda|
              add_offense(node) if gda.table_names.count >= count_joins
            end
          end

          # @return [Integer]
          def count_joins
            cop_config["CountJoins"]
          end
        end
      end
    end
  end
end