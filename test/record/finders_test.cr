require "./record_test_helper"

module Trail
  class Record
    class FindersTest < Minitest::Test
      def test_find
        hello = Post.find(1001)
        assert_equal 1001, hello.id
        assert_equal "hello", hello.title
        assert_equal "hello world", hello.body
        assert_equal false, hello.published
        assert hello.created_at.is_a?(Time)
        assert hello.updated_at.is_a?(Time)

        first = Post.find(1002)
        assert_equal 1002, first.id
        assert_equal "first", first.title
        assert_equal "body", first.body
        assert_equal true, first.published
        assert first.created_at.is_a?(Time)
        assert first.updated_at.is_a?(Time)

        assert_raises(RecordNotFound) { Post.find(1209180) }
      end

      def test_find_by
        assert_equal posts(:first), Post.find_by({ title: "first" })
        assert_equal posts(:hello_world), Post.find_by({ title: "hello", published: false })
        assert_raises(RecordNotFound) { Post.find_by({ title: "hello", published: true }) }
      end

      def test_find_by?
        assert_equal posts(:first), Post.find_by?({ title: "first" })
        assert_equal posts(:hello_world), Post.find_by?({ title: "hello", published: false })
        assert_nil Post.find_by?({ title: "hello", published: true })
      end

      def test_first
        assert_equal posts(:second), Post.order(:created_at, :desc).first
        assert_equal posts(:hello_world), Post.order(:created_at, :asc).first
        assert_raises(RecordNotFound) { Post.where({ title: "unknown" }).first }
      end

      def test_first?
        assert_equal posts(:hello_world), Post.order(:created_at, :asc).first?
        assert_nil Post.where({ title: "unknown" }).first?
      end

      def test_last
        assert_equal posts(:hello_world), Post.order(:created_at, :desc).last
        assert_equal posts(:second), Post.order(:created_at, :asc).last
        assert_raises(RecordNotFound) { Post.where({ title: "unknown" }).last }
      end

      def test_last?
        assert_equal posts(:hello_world), Post.order(:created_at, :desc).last?
        assert_nil Post.where({ title: "unknown" }).last?
      end

      def test_to_a
        posts = Post.all.to_a
        assert typeof(posts) == Array(Post)
        assert_equal 3, posts.size
        assert_equal ["first", "hello", "second"], posts.map(&.title.not_nil!).sort
      end

      def test_pluck
        titles = Post.order(:title).pluck(:title)
        assert_equal ["first", "hello", "second"], titles
      end

      def test_select
        posts = Post.select(:title).all
        assert_equal ["first", "hello", "second"], posts.map(&.title.not_nil!).sort
        assert_equal [nil, nil, nil], posts.map(&.created_at)
      end

      def test_where
        posts = Post.where({ published: true }).all
        assert_equal ["first", "second"], posts.map(&.title.not_nil!).sort
      end

      def test_order
        posts = Post.order(:created_at).all
        assert_equal ["hello", "first", "second"], posts.map(&.title)

        posts = Post.order({ created_at: :desc }).all
        assert_equal ["second", "first", "hello"], posts.map(&.title)
      end

      def test_reorder
        posts = Post.order({ created_at: :desc }).reorder(:id).all
        assert_equal ["hello", "first", "second"], posts.map(&.title)
      end

      def test_count
        assert_equal 3, Post.count
        assert_equal 3, Post.count(:published)
        assert_equal 2, Post.count(:published, distinct: true)
        assert_equal({ true => 2, false => 1}, Post.count(group: :published))
        assert_equal({
          [false, "hello world"] => 1,
          [true, "body"] => 2
        }, Post.count(group: {:published, :body}))
      end

      #def test_group
      #  posts = Post.group(:published).count
      #  assert_equal [1001, 1002, 1003], posts.map(&.id)
      #end

      def test_limit
        posts = Post.order(:id).limit(2).all
        assert_equal [1001, 1002], posts.map(&.id)

        posts = Post.order({ id: :desc }).limit(1, 1).all
        assert_equal [1002], posts.map(&.id)
      end
    end
  end
end
