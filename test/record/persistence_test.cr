require "./record_test_helper"

module Trail
  class Record
    class PersistenceTest < Minitest::Test
      def setup
        Record.connection.execute(
          "INSERT INTO posts (id, title, body, published, created_at) VALUES
          (1, 'hello world', 'body', 'f', '#{ 1.month.ago.to_s }'),
          (2, 'first', 'body', 't', '#{ 2.weeks.ago.to_s }'),
          (3, 'second', 'body', 't', '#{ 1.week.ago.to_s }')")
      end

      def teardown
        Record.connection.execute("TRUNCATE posts")
        Record.connection.execute("TRUNCATE comments")
      end

      def test_save
        comment = Comment.new(email: "me@example.com", body: "contents")
        assert comment.new_record?

        # create
        comment.save
        refute comment.new_record?
        assert comment.created_at
        assert comment.updated_at

        comment = Comment.find(comment.id)
        refute comment.new_record?

        # update
        comment.body = "alternate"
        comment.save

        comment = Comment.find(comment.id)
        assert_equal "alternate", comment.body
      end

      def test_create
        comment = Comment.create({ "email" => "me@example.com", "body" => "great!" })
        refute comment.new_record?

        comment = Comment.find(comment.id)
        assert comment.uuid
        assert_equal "me@example.com", comment.email
        assert_equal "great!", comment.body
      end

      def test_update
        post = Post.update(1, { "title" => "Incredible News!" })
        assert_equal "Incredible News!", Post.find(post.id).title
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
