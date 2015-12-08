require "../record_test_helper"

module Trail
  class Record
    class Associations::HasManyTest < Minitest::Test
      def setup
        Post.callbacks.clear
        Comment.callbacks.clear
      end

      def test_collection
        assert_equal [comments(:three)], posts(:first).comments.to_a
        assert_equal ["one", "two", "five"], posts(:hello_world).comments.pluck(:body)
      end

      def test_collection_memoization
        post = posts(:hello_world)
        assert_same post.comments, post.comments
        refute_same post.comments, post.comments(true)
        refute_same post.comments, Post.find(post.id).comments
      end

      def test_collection_setter
        new_comment = Comment.new(email: "you@example.com", body: "test")
        comments = [comments(:one), comments(:four), new_comment]

        posts(:hello_world).comments = comments
        assert_equal_unordered comments.map(&.id), posts(:hello_world).comments(true).to_a.map(&.id)
        assert_equal posts(:hello_world).id, new_comment.post_id

        ifdef test_dependent_delete || test_dependent_destroy
          assert_raises(RecordNotFound) { comments(:two) }
          assert_raises(RecordNotFound) { comments(:five) }
        else
          assert_nil comments(:two).post_id
          assert_nil comments(:five).post_id
        end
      end

      def test_collection_ids
        assert_equal [comments(:four).uuid], posts(:second).comment_ids
        assert_equal [comments(:one).id, comments(:two).id, comments(:five).id], posts(:hello_world).comment_ids
      end

      def test_collection_ids_setter
        comment_ids = [comments(:two).id, comments(:four).id]

        posts(:hello_world).comment_ids = comment_ids
        assert_equal comment_ids, posts(:hello_world).comment_ids

        ifdef test_dependent_delete || test_dependent_destroy
          assert_raises(RecordNotFound) { comments(:one) }
          assert_raises(RecordNotFound) { comments(:five) }
        else
          assert_nil comments(:one).post_id
          assert_nil comments(:five).post_id
        end
      end

      def test_autosave
        post = Post.new(title: "title", body: "body")
        post.comments.build({ "email" => "her@example.com", "body" => "body" })
        post.comments.build({ "email" => "him@example.com", "body" => "body" })
        post.comments.build({ "email" => "she@example.com", "body" => "body" })

        assert post.valid?
        assert post.save
        assert post.persisted?

        post.comments.each do |comment|
          assert comment.persisted?
          assert_equal post.id, comment.post_id
        end
      end

      def test_autosave_with_invalid_record
        post = Post.new(title: "title", body: "body")
        post.comments.build({ "email" => "her@example.com", "body" => "body" })
        post.comments.build({ "email" => "him@example.com", "body" => "" })
        post.comments.build({ "email" => "she@example.com", "body" => "body" })

        assert post.valid?
        refute post.save
        refute post.persisted?
        assert post.errors[:base].any?

        post.comments.each do |comment|
          refute comment.persisted?
          assert_nil comment.post_id
        end
      end

      def test_build
        comment = posts(:first).comments.build
        assert comment.is_a?(Comment)
        assert comment.new_record?
        assert_equal posts(:first).id, comment.post_id
      end

      def test_build_pushes_record_to_loaded_collection
        posts(:first).comments.to_a
        comment = posts(:first).comments.build
        assert_includes posts(:first).comments.to_a, comment
      end

      def test_create
        comment = posts(:second).comments.create({
          "email" => "me@example.com",
          "body" => "some text contents",
        })
        assert comment.is_a?(Comment)
        refute comment.new_record?
        assert_equal posts(:second).id, comment.post_id
        assert_equal "me@example.com", comment.email
        assert_equal "some text contents", comment.body
      end

      def test_create_pushes_record_to_loaded_collection
        posts(:first).comments.to_a
        comment = posts(:first).comments.create({ email: "me@example.com", body: "text" })
        assert_includes posts(:first).comments.to_a, comment
      end

      def test_destroy
        posts(:hello_world).comments.destroy(comments(:one), comments(:five))
        assert_equal [comments(:two).id], posts(:hello_world).comment_ids
        assert_equal [
          "#{comments(:one).id}:before_destroy", "#{comments(:one).id}:around_destroy", "#{comments(:one).id}:after_destroy",
          "#{comments(:five).id}:before_destroy", "#{comments(:five).id}:around_destroy", "#{comments(:five).id}:after_destroy",
        ], Comment.callbacks
      end

      def test_destroy_removes_records_from_loaded_collection
        posts(:hello_world).comments.to_a
        posts(:hello_world).comments.destroy(comments(:two), comments(:five))
        assert_equal [comments(:one).id], posts(:hello_world).comments.map(&.id)
      end

      ifdef test_dependent_destroy
        def test_delete_with_dependent_destroy
          posts(:hello_world).comments.delete(comments(:one), comments(:five))
          assert comments(:one).deleted?
          assert comments(:five).deleted?
          assert_equal [comments(:two)], posts(:hello_world).comments(true).to_a
          refute_empty Comment.callbacks
        end

        def test_clear_with_dependent_destroy
          comment_ids = posts(:hello_world).comment_ids
          posts(:hello_world).comments.clear
          assert_empty posts(:hello_world).comments(true)
          assert_equal 0, Comment.where({ uuid: comment_ids }).count
          refute_empty Comment.callbacks
        end

        def test_dependent_destroy_option
          comment_ids = posts(:hello_world).comment_ids
          assert posts(:hello_world).destroy
          assert_empty posts(:hello_world).comments(true)
          assert_equal 0, Comment.where({ uuid: comment_ids }).count
          refute_empty Comment.callbacks
        end

      elsif test_dependent_delete
        def test_delete_with_dependent_delete_all
          posts(:hello_world).comments.delete(comments(:one), comments(:five))
          assert comments(:one).deleted?
          assert comments(:five).deleted?
          assert_equal [comments(:two)], posts(:hello_world).comments(true).to_a
          assert_empty Comment.callbacks
        end

        def test_clear_with_dependent_delete_all
          comment_ids = posts(:hello_world).comment_ids
          posts(:hello_world).comments.clear
          assert_empty posts(:hello_world).comments(true)
          assert_equal 0, Comment.where({ uuid: comment_ids }).count
          assert_empty Comment.callbacks
        end

        def test_dependent_delete_all_option
          comment_ids = posts(:hello_world).comment_ids
          assert posts(:hello_world).destroy
          assert_empty posts(:hello_world).comments(true)
          assert_equal 0, Comment.where({ uuid: comment_ids }).count
          assert_empty Comment.callbacks
        end

      else
        def test_delete_nullifies_foreign_key_of_removed_records
          posts(:hello_world).comments.delete(comments(:two), comments(:five))
          refute_nil comments(:one).post_id
          assert_nil comments(:two).post_id
          assert_nil comments(:five).post_id
          assert_equal [comments(:one).id], posts(:hello_world).comments.map(&.id)
        end

        def test_clear_nullifies_foreign_key_of_all_records
          posts(:hello_world).comments.clear
          assert_nil comments(:one).post_id
          assert_nil comments(:two).post_id
          assert_nil comments(:five).post_id
          assert_empty posts(:hello_world).comments(true)
        end

        ifdef test_dependent_nullify
          def test_dependent_destroy_option
            comment_ids = posts(:hello_world).comment_ids
            assert posts(:hello_world).destroy
            assert_empty posts(:hello_world).comments(true)

            comments = Comment.where({ uuid: comment_ids })
            assert_equal comment_ids.size, comments.count
            comments.each { |comment| assert_nil comment.post_id }
          end

        elsif test_dependent_exception
          def test_dependent_exception_option_raises_for_non_empty_collection
            assert_raises(DeleteRestrictionError) { posts(:hello_world).destroy }
            refute_empty posts(:hello_world).comments(true)
            Post.find(posts(:hello_world).id)
            refute posts(:hello_world).deleted?
          end

          def test_dependent_exception_option_wont_raise_for_empty_collection
            posts(:hello_world).comments.delete_all
            posts(:hello_world).destroy
          end

        else
          def test_no_dependent_option
            comment_ids = posts(:hello_world).comment_ids
            assert posts(:hello_world).destroy
            refute_empty posts(:hello_world).comments(true)

            comments = Comment.where({ uuid: comment_ids })
            assert_equal comment_ids.size, comments.count

            comments.each do |comment|
              assert_equal posts(:hello_world).id, comment.post_id
            end
          end
        end
      end
    end
  end
end
