require "../test_helper"
require "http/request"

module Trail::Routing
  # TODO: test params
  # TODO: test route precedence
  class MapperTest < Minitest::Test
    module App
      class MapperController < Trail::Controller
        def match
          render text: "OK: #{ request.method }"
        end

        def root
          render text: "ROOT: #{ request.method }"
        end
      end

      {{ run "../fixtures/routes/mapper.cr" }}

      class MapperController
        include App::NamedRoutes
      end
    end

    {% for method in %w(options head get post put patch delete) %}
      def test_{{ method.id }}
        response = dispatch({{ method.upcase }}, "/match/{{ method.id }}")
        assert_equal 200, response.status_code
        assert_match "OK: {% method.id %}", response.body
      end
    {% end %}

    def test_match_via
      response = dispatch("GET", "/")
      assert_equal 200, response.status_code
      assert_match "ROOT: GET", response.body

      response = dispatch("POST", "/")
      assert_equal 200, response.status_code
      assert_match "ROOT: POST", response.body
    end

    def test_routing_error
      ex = assert_raises(RoutingError) { dispatch("GET", "/no/such/route") }
      assert_match "No route for GET \"/no/such/route\"", ex.message

      assert_raises(RoutingError) { dispatch("GET", "/match/delete") }
      assert_raises(RoutingError) { dispatch("DELETE", "/match/get") }
    end

    def test_named_routes
      request = HTTP::Request.new("GET", "/")
      request.headers["Host"] = "example.com"
      request.headers["X-Forwarded-Proto"] = "https"
      controller = App::MapperController.new(request, {} of String => String, "")

      assert_equal "/", controller.root_path
      assert_equal "https://example.com/", controller.root_url

      assert_equal "ssh://test.host/",
        controller.root_url(protocol: "ssh", host: "test.host")
    end

    def test_named_route_params
      request = HTTP::Request.new("GET", "/")
      request.headers["Host"] = "test.host"
      controller = App::MapperController.new(request, {} of String => String, "")

      assert_equal "/posts/123", controller.post_path(123)
      assert_equal "/posts/123/comments/456", controller.post_comment_path(123, 456)

      assert_equal "/posts/123/comments/456.html",
        controller.post_comment_path(123, 456, format: "html")

      assert_equal "/posts/6757/comments/98172.xml",
        controller.post_comment_path("6757", "98172", format: "xml")

      assert_equal "http://test.host/posts/6757/comments/98172.xml",
        controller.post_comment_url("6757", "98172", format: "xml")
    end

    def dispatch(method, url)
      dispatcher.dispatch(HTTP::Request.new(method, url))
    end

    def dispatcher
      @app ||= App::Dispatcher.new
    end
  end
end
