require "./test_helper"
require "earl/http_server"

class Frost::RouterTest < Minitest::Test
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
  end

  def teardown
    Frost::Router.clear
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

  def test_match
    Frost.draw_routes do
      match "link", "/test", controller: X, action: "before"
    end

    request "link", "/test", body: "X#before"
    request "LINK", "/test", body: "X#before"
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
    skip "TODO: write test"
  end

  def test_scope
    skip "TODO: write test"
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
