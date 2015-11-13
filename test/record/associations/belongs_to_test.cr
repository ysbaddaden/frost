require "../record_test_helper"

module Trail
  class Record
    class Associations::BelongsToTest < Minitest::Test
      def test_association
        assert_equal Post.find(1001), Comment.find("2e4834e0-11c7-40d1-a52f-3b2923d1b5a4").post
        assert_equal Post.find(1003), Comment.find("b6e34677-cabd-474c-82f2-90fa20324003").post
      end

      def test_association_memoization
        comment = Comment.find("2e4834e0-11c7-40d1-a52f-3b2923d1b5a4")
        assert_same comment.post, comment.post

        comment.post.title = "blank"
        refute_same comment.post, comment.post(true)
        refute_equal "blank", comment.post.title
      end

      def test_association_setter
        comment = Comment.find("b6e34677-cabd-474c-82f2-90fa20324003")
        post = Post.find(1001)

        assert_same post, comment.post = post
        assert_equal 1001, comment.post_id
        assert_equal post, comment.post
      end

      def test_association_setter_with_unsaved_record
        comment = Comment.find("b6e34677-cabd-474c-82f2-90fa20324003")
        comment.post = Post.new
        assert comment.post.new_record?
        assert_nil comment.post_id
      end

      def test_build_association
        comment = Comment.find("b6e34677-cabd-474c-82f2-90fa20324003")
        post = comment.build_post({ "title" => "test", "body" => "test" })

        assert post.is_a?(Post)
        assert_nil post.id
        assert_nil comment.post_id
        assert_same post, comment.post
      end

      def test_create_association
        comment = Comment.find("b6e34677-cabd-474c-82f2-90fa20324003")
        post = comment.create_post({ "id" => 999, "title" => "test", "body" => "test" })

        assert post.is_a?(Post)
        assert_equal 999, post.id
        assert_equal 999, comment.post_id
        assert_same post, comment.post
      end
    end
  end
end
