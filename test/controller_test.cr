require "./test_helper"

class Frost::ControllerTest < Minitest::Test
  include Frost::Controller::TestHelper

  struct LayoutPage < Frost::HTML
    def template(&block) : Nil
      doctype
      html do
        body(&block)
      end
    end
  end

  struct IndexPage < Frost::HTML
    def initialize(@posts : Enumerable(Int32))
    end

    def template : Nil
      render LayoutPage.new do
        h1 "X#index"
        ul do
          @posts.each { |post| li post }
        end
      end
    end
  end

  struct ShowPage < Frost::HTML
    def initialize(@post : Int32)
    end

    def template : Nil
      render LayoutPage.new do
        h1 "X#show: #{@post}"
      end
    end
  end

  class XController < Controller
    def redirect
      if st = status
        redirect_to "https://some.other/resource", status: st
      else
        redirect_to "https://some.other/resource"
      end
    end

    def head
      if st = status
        head st
      else
        head :no_content
      end
    end

    def plain
      if st = status
        render plain: "this is a plain text response", status: st
      else
        render plain: "this is a plain text response"
      end
    end

    def html
      if st = status
        render html: "<p>this is a <strong>HTML</strong> response</p>", status: st
      else
        render html: "<p>this is a <strong>HTML</strong> response</p>"
      end
    end

    def json
      if st = status
        render json: { "status" => "error", "description" => "Some error message" }, status: st
      else
        render json: { "status" => "error", "description" => "Some error message" }
      end
    end

    def data_string
      send_data_with "some raw data"
    end

    def data_bytes
      send_data_with ("\0" * 128).to_slice
    end

    def data_io
      send_data_with IO::Memory.new("\b" * 128)
    end

    def index
      posts = [1, 2, 3]
      render IndexPage.new(posts)
    end

    def show
      post = 1
      render ShowPage.new(post)
    end

    def default
    end

    def no_template
    end

    private def send_data_with(object)
      filename = params.route["filename"]?
      disposition = params.route["disposition"]?
      type = params.route["type"]?

      if filename && disposition
        send_data object, filename: filename, disposition: disposition, type: type
      elsif filename
        send_data object, filename: filename, type: type
      elsif disposition
        send_data object, disposition: disposition, type: type
      elsif st = status
        send_data object, type: type, status: st
      else
        send_data object, type: type
      end
    end

    def file
      path = params.route["path"]? || "test/test_helper.cr"
      filename = params.route["filename"]?
      disposition = params.route["disposition"]?
      type = params.route["type"]?

      if filename && disposition
        send_file path, filename: filename, disposition: disposition, type: type
      elsif filename
        send_file path, filename: filename, type: type
      elsif disposition
        send_file path, disposition: disposition, type: type
      elsif st = status
        send_file path, type: type, status: st
      else
        send_file path, type: type
      end
    end

    private def status
      if status = params.route["status"]?
        HTTP::Status.from_value(status.to_i)
      end
    end
  end

  def test_redirect
    response = call :redirect
    assert_equal HTTP::Status::SEE_OTHER, response.status
    assert_equal "https://some.other/resource", response.headers["location"]

    response = call :redirect, { "status" => "301" }
    assert_equal HTTP::Status::MOVED_PERMANENTLY, response.status
    assert_equal "https://some.other/resource", response.headers["location"]
  end

  def test_head
    response = call :head
    assert_equal HTTP::Status::NO_CONTENT, response.status
    assert_nil response.headers["content-type"]?
    assert_empty response.body

    response = call :head, { "status" => "422" }
    assert_equal HTTP::Status::UNPROCESSABLE_ENTITY, response.status
    assert_nil response.headers["content-type"]?
    assert_empty response.body
  end

  def test_render_plain
    response = call :plain
    assert_equal HTTP::Status::OK, response.status
    assert_equal "text/plain; charset=utf-8", response.headers["content-type"]
    assert_equal "this is a plain text response", response.body

    response = call :plain, { "status" => "409" }
    assert_equal HTTP::Status::CONFLICT, response.status
    assert_equal "text/plain; charset=utf-8", response.headers["content-type"]
    assert_equal "this is a plain text response", response.body
  end

  def test_render_html
    response = call :html
    assert_equal HTTP::Status::OK, response.status
    assert_equal "text/html; charset=utf-8", response.headers["content-type"]
    assert_equal "<p>this is a <strong>HTML</strong> response</p>", response.body

    response = call :html, { "status" => "422" }
    assert_equal HTTP::Status::UNPROCESSABLE_ENTITY, response.status
    assert_equal "text/html; charset=utf-8", response.headers["content-type"]
    assert_equal "<p>this is a <strong>HTML</strong> response</p>", response.body
  end

  def test_render_json
    response = call :json
    assert_equal HTTP::Status::OK, response.status
    assert_equal "application/json; charset=utf-8", response.headers["content-type"]
    body = JSON.parse(response.body)
    assert_equal "error", body.as_h["status"]
    assert_equal "Some error message", body.as_h["description"]

    response = call :json, { "status" => "500" }
    assert_equal HTTP::Status::INTERNAL_SERVER_ERROR, response.status
    assert_equal "application/json; charset=utf-8", response.headers["content-type"]
    body = JSON.parse(response.body)
    assert_equal "error", body.as_h["status"]
    assert_equal "Some error message", body.as_h["description"]
  end

  {% for name in %w[string bytes io] %}
    def test_send_data_with_{{name.id}}
      contents =
        case {{name}}
        when "string" then "some raw data"
        when "bytes" then "\0" * 128
        when "io" then "\b" * 128
        end

      response = call :data_{{name.id}}
      assert_equal HTTP::Status::OK, response.status
      assert_equal "application/octet-stream", response.headers["content-type"]
      assert_equal "inline", response.headers["content-disposition"]
      assert_equal contents, response.body

      response = call :data_{{name.id}}, { "status" => "201" }
      assert_equal HTTP::Status::CREATED, response.status
      assert_equal "application/octet-stream", response.headers["content-type"]
      assert_equal "inline", response.headers["content-disposition"]
      assert_equal contents, response.body

      response = call :data_{{name.id}}, { "filename" => "example.jpg" }
      assert_equal HTTP::Status::OK, response.status
      assert_equal "image/jpeg", response.headers["content-type"]
      assert_equal "inline; filename=example.jpg", response.headers["content-disposition"]
      assert_equal contents, response.body

      response = call :data_{{name.id}}, { "disposition" => "attachment" }
      assert_equal HTTP::Status::OK, response.status
      assert_equal "application/octet-stream", response.headers["content-type"]
      assert_equal "attachment", response.headers["content-disposition"]
      assert_equal contents, response.body

      response = call :data_{{name.id}}, { "filename" => "report.pdf", "disposition" => "attachment" }
      assert_equal HTTP::Status::OK, response.status
      assert_equal "application/pdf", response.headers["content-type"]
      assert_equal "attachment; filename=report.pdf", response.headers["content-disposition"]
      assert_equal contents, response.body

      response = call :data_{{name.id}}, { "filename" => "schema.json", "type" => "application/schema+json", "disposition" => "attachment" }
      assert_equal HTTP::Status::OK, response.status
      assert_equal "application/schema+json", response.headers["content-type"]
      assert_equal "attachment; filename=schema.json", response.headers["content-disposition"]
      assert_equal contents, response.body

      response = call :data_{{name.id}}, { "filename" => "feed.xml", "type" => "application/rss+xml" }
      assert_equal HTTP::Status::OK, response.status
      assert_equal "application/rss+xml", response.headers["content-type"]
      assert_equal "inline; filename=feed.xml", response.headers["content-disposition"]
      assert_equal contents, response.body

      response = call :data_{{name.id}}, { "filename" => "日本語学習サイト.html" }
      assert_equal HTTP::Status::OK, response.status
      assert_equal "text/html", response.headers["content-type"]
      assert_equal "inline; filename*=UTF-8''%E6%97%A5%E6%9C%AC%E8%AA%9E%E5%AD%A6%E7%BF%92%E3%82%B5%E3%82%A4%E3%83%88.html", response.headers["content-disposition"]
      assert_equal contents, response.body
    end
  {% end %}

  def test_send_file
    response = call :file
    assert_equal HTTP::Status::OK, response.status
    assert_equal "application/octet-stream", response.headers["content-type"]
    assert_equal "inline; filename=test_helper.cr", response.headers["content-disposition"]
    assert_equal File.read("test/test_helper.cr"), response.body

    response = call :file, { "status" => "400" }
    assert_equal HTTP::Status::BAD_REQUEST, response.status
    assert_equal "application/octet-stream", response.headers["content-type"]
    assert_equal "inline; filename=test_helper.cr", response.headers["content-disposition"]
    assert_equal File.read("test/test_helper.cr"), response.body

    response = call :file, { "disposition" =>  "attachment", "type" => "text/plain" }
    assert_equal HTTP::Status::OK, response.status
    assert_equal "text/plain", response.headers["content-type"]
    assert_equal "attachment; filename=test_helper.cr", response.headers["content-disposition"]
    assert_equal File.read("test/test_helper.cr"), response.body

    response = call :file, { "path" => "test/fixtures/files/empty.jpg" }
    assert_equal HTTP::Status::OK, response.status
    assert_equal "image/jpeg", response.headers["content-type"]
    assert_equal "inline; filename=empty.jpg", response.headers["content-disposition"]
    assert_equal File.read("test/fixtures/files/empty.jpg"), response.body

    response = call :file, { "path" => "test/fixtures/files/empty.png", "filename" => "dot.png"}
    assert_equal HTTP::Status::OK, response.status
    assert_equal "image/png", response.headers["content-type"]
    assert_equal "inline; filename=dot.png", response.headers["content-disposition"]
    assert_equal File.read("test/fixtures/files/empty.png"), response.body
  end

  def test_render_view
    response = call :index
    assert_equal HTTP::Status::OK, response.status
    assert_equal "<!DOCTYPE html><html><body><h1>X#index</h1><ul><li>1</li><li>2</li><li>3</li></ul></body></html>", response.body

    response = call :show
    assert_equal HTTP::Status::OK, response.status
    assert_equal "<!DOCTYPE html><html><body><h1>X#show: 1</h1></body></html>", response.body
  end
end
