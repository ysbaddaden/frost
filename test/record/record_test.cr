require "./record_test_helper"

module Trail
  class RecordTest < Minitest::Test
    def test_table_name
      assert_equal "posts", Post.table_name
      assert_equal "comments", Comment.table_name
    end

    def test_primary_key
      assert_equal "id", Post.primary_key
      assert_equal "uuid", Comment.primary_key
    end

    def test_attribute_names
      assert_equal({"id", "title", "body", "published", "views", "created_at", "updated_at"}, Post.attribute_names)
      assert_equal({"uuid", "email", "body", "created_at", "updated_at"}, Comment.attribute_names)
    end

    def test_initialize
      blank = Post.new
      assert_nil blank.id
      assert_nil blank.title
      assert_nil blank.body
      assert_equal false, blank.published
      assert_equal 0, blank.views
      assert_nil blank.created_at
      assert_nil blank.updated_at

      post = Post.new(title: "Hello", body: "lorem ipsum", published: true)
      assert_nil post.id
      assert_equal "Hello", post.title
      assert_equal "lorem ipsum", post.body
      assert_equal true, post.published
      assert_equal 0, post.views
      assert_nil post.created_at
      assert_nil post.updated_at
    end

    def test_build
      skip "fails to compile with 'can't cast String to Int32' or 'can't cast String to Bool' error messages"

      #post = Post.build({ "title" => "Hello", "body" => "lorem ipsum", "published" => "1" })
      #assert_nil post.id
      #assert_equal "Hello", post.title
      #assert_equal "lorem ipsum", post.body
      #assert_equal true, post.published
      #assert_equal 0, post.views
      #assert_nil post.created_at
      #assert_nil post.updated_at
    end

    def test_to_hash
      post = Post.new(title: "Hello", body: "lorem ipsum", published: true)
      assert_equal({
        "id" => nil,
        "title" => "Hello",
        "body" => "lorem ipsum",
        "published" => true,
        "views" => 0,
        "created_at" => nil,
        "updated_at" => nil,
      }, post.to_hash)
    end

    def test_to_tuple
      post = Post.new(title: "Hello", body: "lorem ipsum", published: true)
      assert_equal({nil, "Hello", "lorem ipsum", true, 0, nil, nil}, post.to_tuple)
    end
  end
end
