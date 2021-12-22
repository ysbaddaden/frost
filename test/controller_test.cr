require "./test_helper"

class Frost::ControllerTest < Minitest::Test
  class X < Controller
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
      render plain: "this is a plain text response"
    end

    def html
      render html: "<p>this is a <strong>HTML</strong> response</p>"
    end

    private def status
      if status = params["status"]?
        HTTP::Status.from_value(status.to_i)
      end
    end
  end

  def test_redirect
    response = call :redirect
    assert_equal HTTP::Status::FOUND, response.status
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
  end

  def test_render_html
    response = call :html
    assert_equal HTTP::Status::OK, response.status
    assert_equal "text/html; charset=utf-8", response.headers["content-type"]
    assert_equal "<p>this is a <strong>HTML</strong> response</p>", response.body
  end

  def test_render_json
    skip "TODO: missing test"
  end

  def test_send_data
    skip "TODO: missing test"
  end

  def test_send_file
    skip "TODO: missing test"
  end

  macro call(action, params = {} of String => String)
    %context, %io = new_context
    %controller = X.new(%context, ({{params}}).reduce(Hash(String, String?).new) { |a, (k, v)| a[k] = v; a })
    %controller.{{action.id}}()
    %context.response.close
    HTTP::Client::Response.from_io(%io.rewind)
  end

  private def new_context
    request = HTTP::Request.new("GET", "/")
    response = HTTP::Server::Response.new(io = IO::Memory.new)
    context = HTTP::Server::Context.new(request, response)
    {context, io}
  end
end
