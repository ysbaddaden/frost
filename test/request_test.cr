require "./test_helper"

class Frost::RequestTest < Minitest::Test
  def test_xhr?
    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers.new))
    refute request.xhr?

    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "x-requested-with" => "something-else",
    }))
    refute request.xhr?

    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "x-requested-with" => "xmlhttprequest",
    }))
    assert request.xhr?
  end

  def test_content_type?
    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers.new))
    assert_nil request.content_type

    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "content-type" => "application/json;charset=utf-8",
    }))
    assert_equal "application/json;charset=utf-8", request.content_type
  end

  def test_json?
    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers.new))
    refute request.json?

    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "content-type" => "application/json;charset=utf-8",
    }))
    assert request.json?
  end

  def test_urlencoded?
    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers.new))
    refute request.urlencoded?

    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "content-type" => "application/x-www-form-urlencoded",
    }))
    assert request.urlencoded?
  end

  def test_urlencoded?
    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers.new))
    refute request.multipart?

    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "content-type" => "multipart/form-data",
    }))
    assert request.multipart?
  end

  def test_accept?
    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "accept" => "*/*",
    }))
    refute request.accept?("text/event-stream")
    assert request.accept?("text/event-stream", implicit: true)
    refute request.accept?("text/plain")
    assert request.accept?("text/plain", implicit: true)
    refute request.accept?("image/jpeg")
    assert request.accept?("image/jpeg", implicit: true)

    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "accept" => "text/event-stream",
    }))
    assert request.accept?("text/event-stream")
    refute request.accept?("text/plain")
    refute request.accept?("image/jpeg")

    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "accept" => "text/*",
    }))
    refute request.accept?("text/event-stream")
    assert request.accept?("text/event-stream", implicit: true)
    refute request.accept?("text/plain")
    assert request.accept?("text/plain", implicit: true)
    refute request.accept?("text-x/other", implicit: true)
    refute request.accept?("image/jpeg", implicit: true)

    request = Request.new(HTTP::Request.new("GET", "/", HTTP::Headers{
      "accept" => "text/html , application/xhtml+xml, application/xml;q=0.9",
    }))
    assert request.accept?("text/html")
    assert request.accept?("application/xhtml+xml")
    assert request.accept?("application/xml")
  end
end
