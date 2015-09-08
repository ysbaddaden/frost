require "./record_test_helper"

module Trail
  class Record
    class PersistenceTest < Minitest::Test
      def test_save
        comment = Comment.new(
          post_id: posts(:second).id,
          email: "me@example.com",
          body: "contents"
        )
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
        comment = Comment.create({
          "post_id" => posts(:second).id,
          "email" => "me@example.com",
          "body" => "great!"
        })
        refute comment.new_record?

        comment = Comment.find(comment.id)
        assert comment.uuid
        assert_equal "me@example.com", comment.email
        assert_equal "great!", comment.body
      end

      def test_update
        post = Post.update(posts(:second).id, { "title" => "Incredible News!" })
        assert_equal "Incredible News!", Post.find(post.id).title
      end

      def test_delete
        Post.delete(posts(:second).id)
        assert_raises(RecordNotFound) { Post.find(posts(:second).id) }
      end
    end
  end
end
