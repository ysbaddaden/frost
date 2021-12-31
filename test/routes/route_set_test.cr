require "../test_helper"

class Frost::Routes::RouteSetTest < Minitest::Test
  @routes = Frost::Routes::RouteSet(Symbol).new

  def test_simple
    @routes.add "/posts", :index
    @routes.add "/posts/published", :published

    assert_route :index, "/posts"
    assert_route :index, "/posts/"
    assert_route :index, "//posts//"
    assert_route :published, "/posts/published"
    assert_route :published, "/posts/published/"
    assert_route :published, "//posts//published//"
  end

  def test_root
    @routes.add "/", :root
    @routes.add "/posts", :index

    assert_route :root, "/"
    assert_route :index, "/posts"
    assert_nil @routes.find("/unknown/path")
  end

  def test_params
    @routes.add "/posts/:id", :posts_show
    @routes.add "/posts/:post_id/comments", :comments_index
    @routes.add "/posts/:post_id/comments/:id", :comments_show

    assert_route :posts_show, "/posts/123",
      params: { "id" => "123" }

    assert_route :comments_index, "/posts/45/comments",
      params: { "post_id" => "45" }

    assert_route :comments_show, "/posts/45/comments/6789",
      params: { "post_id" => "45", "id" => "6789"}

    assert_route :posts_show, "/posts/%C3%A9%C3%A0%C3%B4",
      params: { "id" => "éàô" }

    assert_route :comments_show, "/posts/%C3%A9/comments/%C3%A0%C3%B4",
      params: { "post_id" => "é", "id" => "àô" }
  end

  def test_specific_route_takes_precedence_over_param
    @routes.add "/posts/pending", :pending
    @routes.add "/posts/:id", :show
    @routes.add "/posts/published", :published

    assert_route :show, "/posts/123"
    assert_route :published, "/posts/published"
    assert_route :pending, "/posts/pending"
  end

  def test_glob
    @routes.add "/*path", :catchall
    @routes.add "/api/*path", :api_catchall
    @routes.add "/", :root

    assert_route :root, "/"

    assert_route :catchall, "unknown",
      { "path" => "unknown" }

    assert_route :catchall, "expecting/404/status/response.json",
      { "path" => "expecting/404/status/response.json", "format" => "json" }

    assert_route :api_catchall, "/api/another/404",
      params: { "path" => "another/404" }
  end

  def test_format
    @routes.add "/posts", :index
    @routes.add "/posts/:id", :show
    @routes.add "/posts/:id.pdf", :show_pdf

    assert_route :index, "/posts",
      params: Frost::Routes::Params.new

    assert_route :index, "/posts.html",
      params: { "format" => "html" }

    assert_route :show, "/posts/123.html",
      params: { "id" => "123", "format" => "html" }

    assert_route :show, "/posts/123.json",
      params: { "id" => "123", "format" => "json" }

    assert_route :show_pdf, "/posts/123.pdf",
      params: { "id" => "123", "format" => "pdf" }
  end

  private def assert_route(expected, path, params = nil, file = __FILE__, line = __LINE__)
    assert match = @routes.find(path), nil, file, line

    if match
      assert_equal expected, match.payload, nil, file, line

      if params
        assert_equal params, match.params, nil, file, line
      end
    end
  end
end
