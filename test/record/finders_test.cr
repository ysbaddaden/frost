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

      def test_find
        hello = Post.find(1)
        assert_equal 1, hello.id
        assert_equal "hello world", hello.title
        assert_equal "body", hello.body
        assert_equal false, hello.published
        assert hello.created_at.is_a?(Time)
        assert hello.updated_at.is_a?(Nil)

        first = Post.find(2)
        assert_equal 2, first.id
        assert_equal "first", first.title
        assert_equal "body", first.body
        assert_equal true, first.published
        assert first.created_at.is_a?(Time)
        assert first.updated_at.is_a?(Nil)
      end

      def test_all
        posts = Post.all
        assert typeof(posts) == Array(Post)
        assert_equal 3, posts.size
        assert_equal [1, 2, 3], posts.map(&.id.not_nil!).sort
      end

      def test_pluck
        titles = Post.order(:id).pluck(:title)
        assert_equal ["hello world", "first", "second"], titles
      end

      def test_select
        posts = Post.select(:id).all
        assert_equal [1, 2, 3], posts.map(&.id.not_nil!).sort
        assert_equal [nil, nil, nil], posts.map(&.created_at)
      end

      def test_where
        posts = Post.where({ published: true }).all
        assert_equal [2, 3], posts.map(&.id.not_nil!).sort
      end

      def test_order
        posts = Post.order(:created_at).all
        assert_equal [1, 2, 3], posts.map(&.id.not_nil!)

        posts = Post.order({ created_at: :desc }).all
        assert_equal [3, 2, 1], posts.map(&.id.not_nil!)
      end

      def test_reorder
        posts = Post.order({ created_at: :desc }).reorder(:id).all
        assert_equal [1, 2, 3], posts.map(&.id.not_nil!)
      end

      #def test_group
      #  posts = Post.group(:published).count
      #  assert_equal [1, 2, 3], posts.map(&.id.not_nil!)
      #end

      def test_limit
        posts = Post.order(:id).limit(2).all
        assert_equal [1, 2], posts.map(&.id.not_nil!)

        posts = Post.order({ id: :desc }).limit(1, 1).all
        assert_equal [2], posts.map(&.id.not_nil!)
      end
    end
  end
end
