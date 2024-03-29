# frozen_string_literal: true

RSpec.shared_examples :mysql2_cop_common_examples do
  context "db.xquery with embed variable string" do
    it "does not register an offense" do
      # c.f. https://github.com/isucon/isucon10-qualify/blob/7e6b6cfb672cde2c57d7b594d0352dc48ce317df/webapp/ruby/app.rb#L244
      expect_no_offenses(<<~RUBY)
        count = db.xquery("\#{count_prefix}\#{search_condition}", query_params).first[:count]
      RUBY
    end
  end

  context "Non DML" do
    include_context :database_cop

    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        db.query('BEGIN')
      RUBY
    end
  end

  context "Unknown AST" do
    include_context :database_cop

    it "does not register an offense" do
      # c.f. https://github.com/isucon/isucon11-final/blob/a4ca72f2b4c470d93afe9edd572a2dbd563308fe/webapp/ruby/app.rb#L764-L803
      expect_no_offenses(<<~RUBY)
        query = "SELECT `announcements`.`id`, `courses`.`id` AS `course_id`, `courses`.`name` AS `course_name`, `announcements`.`title`, NOT `unread_announcements`.`is_deleted` AS `unread`" \
          " FROM `announcements`" \
          " JOIN `courses` ON `announcements`.`course_id` = `courses`.`id`" \
          " JOIN `registrations` ON `courses`.`id` = `registrations`.`course_id`" \
          " JOIN `unread_announcements` ON `announcements`.`id` = `unread_announcements`.`announcement_id`" \
          " WHERE 1=1"
        args = []

        if params[:course_id] && !params[:course_id].empty?
          query.concat(" AND `announcements`.`course_id` = ?")
          args.push(params[:course_id])
        end

        query.concat(
          " AND `unread_announcements`.`user_id` = ?" \
          " AND `registrations`.`user_id` = ?" \
          " ORDER BY `announcements`.`id` DESC"
        )
        args.push(user_id, user_id)

        page = unless params[:page]
          1
        else
          Integer(params[:page]) rescue halt 400, "Invalid page."
        end
        limit = 20
        offset = limit * (page - 1)

        # limitより多く上限を設定し、実際にlimitより多くレコードが取得できた場合は次のページが存在する
        query.concat " LIMIT \#{(limit+1).to_i} OFFSET \#{offset.to_i}"

        announcements = db.xquery(query, *args).map do |a|
          {
            id: a[:id],
            course_id: a[:course_id],
            course_name: a[:course_name],
            title: a[:title],
            unread: a[:unread] == 1, # cast_booleans doesn't work as it is a computed value
          }
        end
      RUBY
    end
  end

  context "without FROM" do
    include_context :database_cop

    it "does not register an offense" do
      # c.f. https://github.com/isucon/isucon10-final/blob/e858b2588a199f9c7407baacf48b53126b8aeed6/webapp/ruby/app.rb#L711
      expect_no_offenses(<<~RUBY)
        team_id = db.xquery('SELECT LAST_INSERT_ID() AS `id`').first&.fetch(:id)
      RUBY
    end
  end
end
