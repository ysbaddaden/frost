require "../record_test_helper"

module Trail
  class Record
    class Associations::BelongsToTest < Minitest::Test
      def setup
        User.callbacks.clear
      end

      def test_association
        assert_equal posts(:hello_world), comments(:one).post
        assert_equal posts(:second), comments(:four).post
      end

      def test_association_memoization
        comment = comments(:one)
        assert_same comment.post, comment.post

        comment.post.title = "blank"
        refute_same comment.post, comment.post(true)
        refute_equal "blank", comment.post.title
      end

      def test_association_setter
        comment = comments(:four)
        post = posts(:hello_world)
        assert_same post, comment.post = post
        assert_equal 1001, comment.post_id
        assert_equal post, comment.post
      end

      def test_association_setter_with_unsaved_record
        comment = comments(:four)
        comment.post = Post.new
        assert comment.post.new_record?
        assert_nil comment.post_id
      end

      def test_autosave
        profile = Profile.new(nickname: "Walter")
        user = User.new(email: "walt@example.com")

        assert_same user, profile.user = user
        assert_nil profile.user_id
        #assert_same profile, user.profile

        assert profile.save
        assert user.persisted?
        assert_equal user.id, profile.user_id
      end

      def test_autosave_with_invalid_record
        profile = Profile.new(nickname: "Walter")
        user = User.new(email: "")

        assert_same user, profile.user = user
        assert profile.valid?

        refute profile.save
        refute user.persisted?
        assert_nil profile.user_id
      end

      def test_build_association
        post = comments(:four).build_post({ "title" => "test", "body" => "test" })
        assert post.is_a?(Post)
        refute post.persisted?

        assert_nil post.id
        assert_nil comments(:four).post_id
        assert_same post, comments(:four).post
      end

      def test_create_association
        post = comments(:four).create_post({ "id" => 999, "title" => "test", "body" => "test" })
        assert post.is_a?(Post)
        assert post.persisted?

        assert_equal 999, post.id
        assert_equal 999, comments(:four).post_id
        assert_same post, comments(:four).post
      end

      def test_create_association_with_invalid_record
        post = comments(:four).create_post({ "id" => 999 })
        assert post.is_a?(Post)
        refute post.persisted?

        assert_equal 999, post.id
        assert_equal 999, comments(:four).post_id
        assert_same post, comments(:four).post
      end

      def test_bang_create_association
        post = comments(:four).create_post({ "id" => 999, "title" => "test", "body" => "test" })
        assert post.is_a?(Post)
        assert post.persisted?

        assert_equal 999, post.id
        assert_equal 999, comments(:four).post_id
        assert_same post, comments(:four).post
      end

      def test_bang_create_association_with_invalid_record
        exception = assert_raises(RecordInvalid) do
          comments(:four).create_post!({ "id" => 999 })
        end
        assert exception.record.is_a?(Post)
        refute exception.record.persisted?
      end

      ifdef test_dependent_destroy
        def test_dependent_destroy_option
          assert profiles(:julien).destroy
          refute User.exists?(profiles(:julien).user_id)
          refute_empty User.callbacks
        end

      elsif test_dependent_delete
        def test_dependent_delete_option
          assert profiles(:julien).destroy
          refute User.exists?(profiles(:julien).user_id)
          assert_empty User.callbacks
        end

      else
        def test_no_dependent_option
          assert profiles(:julien).destroy
          assert User.exists?(profiles(:julien).user_id)
          assert_empty User.callbacks
        end
      end
    end
  end
end
