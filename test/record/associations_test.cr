require "./record_test_helper"

module Trail
  class Record
    class AssociationsTest < Minitest::Test
      def setup
        Record.connection.execute(
          "INSERT INTO posts (id, title, body, published, created_at) VALUES
          (1, 'hello world', 'body', 'f', '#{ 1.month.ago.to_s }'),
          (2, 'first', 'body', 't', '#{ 2.weeks.ago.to_s }'),
          (3, 'second', 'body', 't', '#{ 1.week.ago.to_s }')")

        Record.connection.execute(
          "INSERT INTO comments (uuid, post_id, email, body, created_at) VALUES
          ('2e4834e0-11c7-40d1-a52f-3b2923d1b5a4', 1, 'me@example.com', 'one', '#{ 1.month.ago.to_s }'),
          ('1a604129-cf39-4b23-86c4-cb537ea0d840', 1, 'you@example.com', 'two', '#{ 2.weeks.ago.to_s }'),
          ('2de27d78-142a-4296-b76e-df1d1e1a8b35', 2, 'her@example.com', 'three', '#{ 1.week.ago.to_s }'),
          ('b6e34677-cabd-474c-82f2-90fa20324003', 3, 'him@example.com', 'four', '#{ 3.days.ago.to_s }'),
          ('2c2f8a28-1ac5-4d95-9143-9abacf301aa6', 1, 'kid@example.com', 'five', '#{ 1.day.ago.to_s }')")
      end

      def teardown
        Record.connection.execute("TRUNCATE posts")
        Record.connection.execute("TRUNCATE comments")
      end
    end
  end
end
