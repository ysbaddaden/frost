require "../test_helper"

class RenderController < Frost::Controller
  def not_found
    head 404
  end

  def index
    render "index"
  end

  def text
    response.headers["Content-Type"] = "text/plain"
    render text: "lorem ipsum", status: 206
  end

  def status
    render "index", status: 203
  end

  def custom
    render "show", layout: "custom"
  end

  def template
    render "index", layout: false
  end

  def create
    redirect_to "http://example.org/some/path", status: 201
  end

  def download
    redirect_to "http://example.org/some/path"
  end
end

module Frost
  class Controller
    class RenderingTest < Minitest::Test
      macro run(action_name, format = nil)
        %request = HTTP::Request.new("GET", "/render/{{ action_name.id }}")

        %params = {} of String => ParamType
        {% if format %} %params["format"] = {{ format }} {% end %}

        %controller = RenderController.new(%request, %params, {{ action_name }})
        %controller.run_action do
          %controller.{{ action_name.id }}
        end

        %controller.response
      end

      def test_head
        response = run("not_found")
        assert_equal 404, response.status_code
        assert_empty response.body
      end

      def test_redirect_to
        response = run("download")
        assert_equal 303, response.status_code
        assert_equal "http://example.org/some/path", response.headers["Location"]
        refute response.headers["Content-Type"]?
        assert_empty response.body
      end

      def test_redirect_to_with_status
        response = run("create")
        assert_equal 201, response.status_code
        assert_equal "http://example.org/some/path", response.headers["Location"]
        refute response.headers["Content-Type"]?
        assert_empty response.body
      end

      def test_render_text
        response = run("text")
        assert_equal 206, response.status_code
        assert_equal "text/plain", response.headers["Content-Type"]
        assert_equal "lorem ipsum", response.body
      end

      def test_render_action
        response = run("index")
        assert_equal 200, response.status_code
        assert_equal "text/html", response.headers["Content-Type"]
        assert_match "<title>render/index</title>", response.body
        assert_match "<h1>INDEX</h1>", response.body
      end

      def test_render_status
        response = run("status")
        assert_equal 203, response.status_code
        assert_match "<title>render/status</title>", response.body
      end

      def test_renders_format
        response = run("index", "xml")
        assert_equal 200, response.status_code
        assert_equal "application/xml", response.headers["Content-Type"]
        assert_match /<xml>.+<\/xml>/m, response.body
        assert_match "<array>INDEX</array>", response.body
      end

      def test_renders_without_layout
        response = run("template")
        refute_match "<title>render/template</title>", response.body
        assert_match "<h1>INDEX</h1>", response.body
      end

      def test_renders_custom_layout
        response = run("custom")
        assert_match "<title>CUSTOM</title>", response.body
        assert_match "<h1>SHOW</h1>", response.body
      end
    end
  end
end
