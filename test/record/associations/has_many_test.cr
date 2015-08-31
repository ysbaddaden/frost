require "../associations_test"

module Trail
  class Record
    class Associations::HasManyTest < AssociationsTest
      def test_collection
        assert_equal [Comment.find("2de27d78-142a-4296-b76e-df1d1e1a8b35")], Post.find(2).comments.to_a
        assert_equal ["one", "two", "five"], Post.find(1).comments.pluck(:body)
      end

      def test_collection_memoization
        post = Post.find(1)
        assert_same post.comments, post.comments
        refute_same post.comments, Post.find(1).comments
      end

      #def test_collection_setter
      #end

      #def test_collection_setter_with_unsaved_records
      #end

      def test_collection_ids
        assert_equal ["b6e34677-cabd-474c-82f2-90fa20324003"], Post.find(3).comment_ids

        assert_equal [
          "2e4834e0-11c7-40d1-a52f-3b2923d1b5a4",
          "1a604129-cf39-4b23-86c4-cb537ea0d840",
          "2c2f8a28-1ac5-4d95-9143-9abacf301aa6",
        ], Post.find(1).comment_ids
      end

      #def test_collection_ids_setter
      #end

      #def test_build
      #end

      #def test_create
      #end

      #def test_delete
      #end
    end
  end
end
