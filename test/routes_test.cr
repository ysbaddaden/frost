require "./test_helper"
require "earl/http_server"

class Frost::RoutesTest < Minitest::Test
  class A < Controller
    def a_in
      render plain: "A#in"
    end

    def a_out
      render plain: "A#out"
    end
  end

  class B < Controller
    def b_in
      render plain: "B#in"
    end

    def b_out
      render plain: "B#out"
    end
  end

  class C < Controller
    def c
      render plain: "C#c"
    end
  end

  class D < Controller
    def d
      render plain: "D#d"
    end

    def d2
      render plain: "D#d2"
    end
  end

  class X < Controller
    def before
      render plain: "X#before"
    end

    def after
      render plain: "X#after"
    end

    def api_catch_all
      render plain: "API: #{params["path"]}"
    end

    def catch_all
      render plain: params["path"].to_s
    end

    def extname
      render plain: "FORMAT: #{params["format"]?}"
    end
  end

  class PostsController < Controller
    def index; end
    def show; end
    def new; end
    def edit; end
    def create; end
    def replace; end
    def update; end
    def destroy; end

    def published; end
    def publish; end
  end

  class CommentsController < Controller
    def index; end
    def show; end
    def new; end
    def edit; end
    def create; end
    def replace; end
    def update; end
    def destroy; end

    def pending; end
    def approve; end
  end

  module Api
    module V1
      class CommentsController < Controller
        def index
          render plain: "Api::V1::CommentsController#index"
        end
      end
    end
  end

  def teardown
    Frost.clear_routes
  end

  {% for http_method in %w[options head get post put patch delete].map(&.id) %}
    def test_{{http_method}}
      Frost.draw_routes do
        {{http_method}} "/test_{{http_method}}", X, :before
        {{http_method}} "/test_{{http_method}}_explicit", controller: X, action: "after"
      end

      request "{{http_method}}", "/test_{{http_method}}"
      request "{{http_method}}", "/test_{{http_method}}_explicit"
    end
  {% end %}

  def test_methods
    Frost.draw_routes do
      get    "/posts",     controller: PostsController, action: "index"
      get    "/posts/:id", controller: PostsController, action: "show"
      post   "/posts",     controller: PostsController, action: "create"
      put    "/posts/:id", controller: PostsController, action: "replace"
      patch  "/posts/:id", controller: PostsController, action: "update"
      delete "/posts/:id", controller: PostsController, action: "destroy"
    end

    request :get, "/posts"
    request :get, "/posts/1"
    request :post, "/posts"
    request :put, "/posts/1"
    request :patch, "/posts/1"
    request :delete, "/posts/1"
  end

  def test_match
    Frost.draw_routes do
      match "link", "/test", controller: X, action: "before"
      match "get", "/", controller: X, action: "after"
    end

    request "link", "/test", body: "X#before"
    request "LINK", "/test", body: "X#before"
    request "GET", "/", body: "X#after"
  end

  def test_glob
    Frost.draw_routes do
      get "/api/articles/:id", D, :d
      get "/api/*path", X, :api_catch_all
      get "*path", X, :catch_all
    end

    request "get", "/api/articles/123", body: "D#d"
    request "get", "/api/articles/whatever_path/to_image.jpg", body: "API: articles/whatever_path/to_image.jpg"
    request "get", "/api/articles/123/whatever_path/to_image.jpg", body: "API: articles/123/whatever_path/to_image.jpg"
    request "get", "/api/with/whatever_path/to_image.jpg", body: "API: with/whatever_path/to_image.jpg"
    request "get", "/whatever_path/to_file.pdf", body: "whatever_path/to_file.pdf"
  end

  def test_format
    Frost.draw_routes do
      get "/posts.pdf", D, :d
      get "/posts", X, :extname

      get "/posts/:id", X, :extname
      get "/posts/:id.pdf", D, :d
    end

    request "get", "/posts", body: "FORMAT: "
    request "get", "/posts.json", body: "FORMAT: json"
    request "get", "/posts.rss", body: "FORMAT: rss"
    request "get", "/posts.pdf", body: "D#d"

    request "get", "/posts/:123", body: "FORMAT: "
    request "get", "/posts/:123.json", body: "FORMAT: json"
    request "get", "/posts/:123.rss", body: "FORMAT: rss"
    request "get", "/posts/:123.pdf", body: "D#d"
  end

  def test_controller
    Frost.draw_routes do
      get "/before", X, :before

      controller(A) do
        get "/a", :a_in

        controller(B) do
          get "/b", :b_in

          controller(C) do
            get "/c", :c
          end

          controller(D) do
            get "/d", :d
          end

          get "/b2", :b_out
        end

        controller(D) do
          get "/d2", :d2
        end

        get "/a2", :a_out
      end

      get "/after", X, :after
    end

    request :get, "/before", body: "X#before"
    request :get, "/a", body: "A#in"
    request :get, "/b", body: "B#in"
    request :get, "/c", body: "C#c"
    request :get, "/d", body: "D#d"
    request :get, "/b2", body: "B#out"
    request :get, "/d2", body: "D#d2"
    request :get, "/a2", body: "A#out"
    request :get, "/after", body: "X#after"
    request :get, "/x", status: :not_found
  end

  def test_path
    Frost.draw_routes do
      path "/api" do
        get "", controller: A, action: "a_in"

        path "/posts" do
          get "/:id", controller: D, action: "d"
        end

        get "more", controller: A, action: "a_out"
      end

      get "/", controller: C, action: "c"
    end

    request :get, "/api", body: "A#in"
    request :get, "/api/posts/:id", body: "D#d"
    request :get, "/api/more", body: "A#out"
    request :get, "/", body: "C#c"
  end

  def test_scope
    Frost.draw_routes do
      scope path: "/posts", controller: A do
        get "", action: "a_in"

        scope path: "/comments", controller: B do
          get "", action: "b_in"
          post "", action: "b_out"
        end

        get "more", controller: D, action: "d"
      end

      get "/", controller: C, action: "c"
    end

    request :get, "/posts", body: "A#in"
    request :get, "/posts/more", body: "D#d"
    request :get, "/posts/comments", body: "B#in"
    request :post, "/posts/comments", body: "B#out"
    request :get, "/", body: "C#c"
  end

  def test_namespace
    Frost.draw_routes do
      namespace :api do
        namespace :v1 do
          get "comments", CommentsController, "index"
        end
      end

      get "", controller: X, action: "after"
    end

    request :get, "/api/v1/comments", body: "Api::V1::CommentsController#index"
    request :get, "/", body: "X#after"
  end

  def test_resources
    Frost.draw_routes do
      resources :posts do
        resources :comments do
          collection { get :pending }
          member { post :approve }
        end

        collection { get :published }
        member { post :publish }
      end
    end

    request :get, "/posts"
    request :get, "/posts/new"
    request :post, "/posts"
    request :get, "/posts/1"
    request :get, "/posts/1/edit"
    request :put, "/posts/1"
    request :patch, "/posts/1"
    request :delete, "/posts/1"

    request :get, "/posts/published"
    request :post, "/posts/1/publish"

    request :get, "/posts/1/comments"
    request :get, "/posts/1/comments/new"
    request :post, "/posts/1/comments"
    request :get, "/posts/1/comments/2"
    request :get, "/posts/1/comments/2/edit"
    request :put, "/posts/1/comments/2"
    request :patch, "/posts/1/comments/2"
    request :delete, "/posts/1/comments/2"

    request :get, "/posts/1/comments/pending"
    request :post, "/posts/1/comments/2/approve"
  end

  def test_member_and_collection_must_be_called_inside_resources
    Frost.draw_routes do
      ex = assert_raises { collection {} }
      assert_match /^ERROR: /, ex.message

      ex = assert_raises { member {} }
      assert_match /^ERROR: /, ex.message
    end
  end

  private def request(http_method, path, *, status : HTTP::Status = :ok, body : String? = nil)
    context = HTTP::Server::Context.new(
      request: HTTP::Request.new(http_method.to_s.upcase, path),
      response: HTTP::Server::Response.new(io = IO::Memory.new)
    )
    Frost.handler.call(context)
    context.response.close

    response = HTTP::Client::Response.from_io(io.rewind)
    assert_equal status, response.status
    assert_equal body, response.body if body
  end
end
