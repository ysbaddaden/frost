require "./record_test_helper"

module Trail
  class Record
    class PersistenceTest < Minitest::Test
      def setup
        Post.callbacks.clear
        Comment.callbacks.clear
      end

      def test_save_creates_record
        comment = Comment.new(post_id: posts(:second).id, email: "me@example.com", body: "contents")
        assert comment.new_record?

        assert comment.save
        refute comment.new_record?
        assert comment.created_at
        assert comment.updated_at

        assert_equal [
          ":before_save",
          ":around_save",
          ":before_create",
          ":around_create",
          "#{comment.id}:after_create",
          "#{comment.id}:after_save",
        ], Comment.callbacks
      end

      def test_save_updates_record
        comment = comments(:one)
        created_at, updated_at = comment.created_at, comment.updated_at

        comment.body = "alternate"
        assert comment.save

        assert_equal [
          "#{comment.id}:before_save",
          "#{comment.id}:around_save",
          "#{comment.id}:before_update",
          "#{comment.id}:around_update",
          "#{comment.id}:after_update",
          "#{comment.id}:after_save",
        ], Comment.callbacks

        comment = Comment.find(comment.id)
        assert_equal "alternate", comment.body
        assert_equal created_at, comment.created_at
        refute_equal updated_at, comment.updated_at
      end

      def test_save_validates_record
        comment = comments(:one)
        comment.body = ""
        refute comment.save
        refute comment.errors.empty?
        assert_empty Comment.callbacks
      end

      def test_save_skips_record_validation
        comment = comments(:one)
        comment.body = ""
        assert comment.save(validate: false)
      end

      def test_bang_save_creates_record
        comment = Comment.new(post_id: posts(:second).id, email: "me@example.com", body: "contents")
        assert comment.save!
        refute comment.new_record?
        assert Comment.exists?(comment.id)

        assert_equal [
          ":before_save",
          ":around_save",
          ":before_create",
          ":around_create",
          "#{comment.id}:after_create",
          "#{comment.id}:after_save",
        ], Comment.callbacks
      end

      def test_bang_save_updates_record
        comment = comments(:one)
        comment.body = "other"
        assert comment.save!
        assert_equal "other", Comment.find(comment.id).body

        assert_equal [
          "#{comment.id}:before_save",
          "#{comment.id}:around_save",
          "#{comment.id}:before_update",
          "#{comment.id}:around_update",
          "#{comment.id}:after_update",
          "#{comment.id}:after_save",
        ], Comment.callbacks
      end

      def test_bang_save_raises_on_invalid_record
        comment = comments(:one)
        comment.body = ""
        exception = assert_raises(RecordInvalid) { comment.save! }
        assert_same comment, exception.record
        assert_empty Comment.callbacks
      end

      def test_bang_save_skips_record_validation
        comment = comments(:one)
        comment.body = ""
        assert comment.save!(validate: false)
      end

      def test_delete
        assert posts(:second).delete
        assert posts(:second).deleted?
        refute Post.exists?(posts(:second).id)
        assert_empty Post.callbacks
      end

      ifdef !test_dependent_exception
        def test_destroy
          assert posts(:second).destroy
          assert posts(:second).deleted?
          refute Post.exists?(posts(:second).id)

          assert_equal [
            "#{posts(:second).id}:before_destroy",
            "#{posts(:second).id}:around_destroy",
            "#{posts(:second).id}:after_destroy",
          ], Post.callbacks
        end
      end
    end

    class Persistence::ClassMethodsTest < Minitest::Test
      def setup
        Post.callbacks.clear
        Comment.callbacks.clear
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

        assert_equal [
          ":before_save",
          ":around_save",
          ":before_create",
          ":around_create",
          "#{comment.id}:after_create",
          "#{comment.id}:after_save",
        ], Comment.callbacks
      end

      def test_update
        post = Post.update(posts(:second).id, { "title" => "Incredible News!" })
        assert post.is_a?(Post)
        assert_equal "Incredible News!", post.title
        assert_equal "Incredible News!", Post.find(post.id).title

        assert_equal [
          "#{post.id}:before_save",
          "#{post.id}:around_save",
          "#{post.id}:before_update",
          "#{post.id}:around_update",
          "#{post.id}:after_update",
          "#{post.id}:after_save",
        ], Post.callbacks
      end

      def test_delete
        assert Post.delete(posts(:second).id)
        refute Post.exists?(posts(:second).id)
        assert_empty Post.callbacks
      end

      ifdef !test_dependent_exception
        def test_destroy
          assert Post.destroy(posts(:hello_world).id)
          refute Post.exists?(posts(:hello_world).id)
          assert_equal [
            "#{posts(:hello_world).id}:before_destroy",
            "#{posts(:hello_world).id}:around_destroy",
            "#{posts(:hello_world).id}:after_destroy",
          ], Post.callbacks
        end
      end
    end
  end
end
