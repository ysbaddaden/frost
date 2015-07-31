require "./record_test_helper"

module Trail
  class Record
    class FindersTest < Minitest::Test
      def setup
        Record.connection.execute(
          "INSERT INTO posts (id, title, body, published, created_at) VALUES
          (1, 'hello world', 'body', 'f', '#{ 1.month.ago.to_s }'),
          (2, 'first', 'body', 't', '#{ 2.weeks.ago.to_s }'),
          (3, 'second', 'body', 't', '#{ 1.week.ago.to_s }')")
      end

      def teardown
        Record.connection.execute("TRUNCATE posts")
      end

      def test_save
        post = Comment.new(email: "me@example.com", body: "contents")
        assert post.new_record?

        # create
        post.save
        refute post.new_record?
        assert post.created_at
        assert post.updated_at

        post = Comment.find(post.id)
        refute post.new_record?

        # update
        post.body = "alternate"
        post.save

        post = Comment.find(post.id)
        assert_equal "alternate", post.body
      end

      def test_delete
        Post.delete(1)
        assert_raises(RecordNotFound) { Post.find(1) }

        Post.find(2).delete
        assert_raises(RecordNotFound) { Post.find(2) }
      end
    end
  end
end
