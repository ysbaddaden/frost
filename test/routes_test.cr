require "./test_helper"
require "earl/http_server"
require "../lib/earl/test/support/rwlock"

class Frost::RoutesTest < Minitest::Test
  class AController < Controller
    def a_in
      render plain: "A#in"
    end

    def a_out
      render plain: "A#out"
    end
  end

  class BController < Controller
    def b_in
      render plain: "B#in"
    end

    def b_out
      render plain: "B#out"
    end
  end

  class CController < Controller
    def c
      render plain: "C#c"
    end
  end

  class DController < Controller
    def d
      render plain: "D#d"
    end

    def d2
      render plain: "D#d2"
    end
  end

  class XController < Controller
    def before
      render plain: "X#before"
    end

    def after
      render plain: "X#after"
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

  @@rwlock = Earl::RWLock.new

  def setup
    @@rwlock.lock_write
  end

  def teardown
    Frost::Routes.handler.clear
  ensure
    @@rwlock.unlock_write
  end

  {% for http_method in %w[options head get post put patch delete].map(&.id) %}
    def test_{{http_method}}
      Frost.routes do
        {{http_method}} "/test_{{http_method}}", &to(XController, before)
        {{http_method}} "/test_{{http_method}}_explicit", &to(XController, after)
      end

      request "{{http_method}}", "/test_{{http_method}}"
      request "{{http_method}}", "/test_{{http_method}}_explicit"
    end
  {% end %}

  def test_methods
    Frost.routes do
      get    "/posts",     &to(PostsController, :index)
      get    "/posts/:id", &to(PostsController, "show")
      post   "/posts",     &to(PostsController, create)
      put    "/posts/:id", &to(PostsController, replace)
      patch  "/posts/:id", &to(PostsController, update)
      delete "/posts/:id", &to(PostsController, destroy)
    end

    request "GET", "/posts"
    request "GET", "/posts/1"
    request "POST", "/posts"
    request "PUT", "/posts/1"
    request "PATCH", "/posts/1"
    request "DELETE", "/posts/1"
  end

  def test_match
    Frost.routes do
      match "/test", via: %w[link connect], &to(XController, before)
      match "/", via: "custom", &to(XController, after)
    end

    request "LINK", "/test", body: "X#before"
    request "CONNECT", "/test", body: "X#before"
    request "CUSTOM", "/", body: "X#after"
  end

  private def request(http_method, path, *, status : HTTP::Status = :ok, body : String? = nil)
    context = HTTP::Server::Context.new(
      request: HTTP::Request.new(http_method.to_s.upcase, path),
      response: HTTP::Server::Response.new(io = IO::Memory.new)
    )
    Frost::Routes.handler.call(context)
    context.response.close

    response = HTTP::Client::Response.from_io(io.rewind)
    assert_equal status, response.status
    assert_equal body, response.body if body
  end
end
