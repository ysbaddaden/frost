require "./test_helper"
require "../src/public"

class Frost::PublicTest < Minitest::Test
  def test_ok
    path = Path.new(__DIR__).join("public")
    public = Public.new(path)

    response = call(public, "favicon.ico")
    assert_equal HTTP::Status::OK, response.status
    assert_equal 0, response.headers["content-length"]?.try(&.to_i)
    assert_equal "image/vnd.microsoft.icon", response.headers["content-type"]?
    assert_equal public.cache_control, response.headers["cache-control"]?
    assert_equal File.info(path.join("favicon.ico")).modification_time.to_rfc2822, response.headers["last-modified"]?
    assert_equal File.read(path.join("favicon.ico")), response.body

    response = call(public, "assets/css/app.css")
    assert_equal HTTP::Status::OK, response.status
    assert_equal File.size(path.join("assets/css/app.css")), response.headers["content-length"]?.try(&.to_i)
    assert_equal "text/css", response.headers["content-type"]?
    assert_equal public.cache_control, response.headers["cache-control"]?
    assert_equal File.info(path.join("assets/css/app.css")).modification_time.to_rfc2822, response.headers["last-modified"]?
    assert_equal File.read(path.join("assets/css/app.css")), response.body

    # never yields
    context, io = new_context
    called = false
    public.call(context, "favicon.ico") { |status| called = true }
    refute called, "expected block to never have been called"
  end

  def test_custom_cache_control
    public = Public.new(Path.new(__DIR__).join("public"))
    public.cache_control = "no-store"

    response = call(public, "favicon.ico")
    assert_equal public.cache_control, response.headers["cache-control"]?
  end

  def test_default_content_type
    # default
    public = Public.new(Path.new(__DIR__).join("public"))
    response = call(public, "file.ext")
    assert_equal public.default_content_type, response.headers["content-type"]?

    # custom
    public = Public.new(Path.new(__DIR__).join("public"))
    public.default_content_type = "unknown/type"
    response = call(public, "file.ext")
    assert_equal "unknown/type", response.headers["content-type"]?
  end

  def test_if_modified_since
    path = Path.new(__DIR__).join("public")
    public = Public.new(path)
    mtime = File.info(path.join("assets/css/app.css")).modification_time

    # file didn't change
    response = call(public, "assets/css/app.css", HTTP::Headers{
      "if-modified-since" => mtime.to_rfc2822,
    })
    assert_equal HTTP::Status::NOT_MODIFIED, response.status
    assert_nil response.headers["content-length"]?
    assert_nil response.headers["content-type"]?
    assert_nil response.headers["cache-control"]?
    assert_nil response.headers["last-modified"]?

    # file has been updated
    response = call(public, "assets/css/app.css", HTTP::Headers{
      "if-modified-since" => (mtime - 10.minutes).to_rfc2822,
    })
    assert_equal HTTP::Status::OK, response.status
    refute_nil response.headers["content-length"]?
    refute_nil response.headers["content-type"]?
    refute_nil response.headers["cache-control"]?
    refute_nil response.headers["last-modified"]?
  end

  def test_not_found
    public = Public.new(Path.new(__DIR__).join("public"))

    # no such file
    response = call(public, "whatever.ext")
    assert_equal HTTP::Status::NOT_FOUND, response.status
    assert_nil response.headers["content-type"]?
    assert_nil response.headers["cache-control"]?
    assert_nil response.headers["last-modified"]?

    # path is a directory
    assert_equal HTTP::Status::NOT_FOUND, call(public, "./").status

    # yields error status
    context, io = new_context
    called = false
    public.call(context, "whatever/else.bin") do |status|
      called = true
      assert_equal HTTP::Status::NOT_FOUND, status
    end
    assert called, "expected block to have been called"
  end

  def test_invalid
    public = Public.new(Path.new(__DIR__).join("public"))

    response = call(public, "/etc/password")
    assert_equal HTTP::Status::BAD_REQUEST, response.status
    assert_nil response.headers["content-type"]?
    assert_nil response.headers["cache-control"]?
    assert_nil response.headers["last-modified"]?

    assert_equal HTTP::Status::BAD_REQUEST, call(public, "../../shard.yml").status
    assert_equal HTTP::Status::BAD_REQUEST, call(public, "./path/../../../shard.yml").status
    assert_equal HTTP::Status::BAD_REQUEST, call(public, "path/\0/path").status

    # yields error status
    context, io = new_context
    called = false
    public.call(context, "path/\0/path") do |status|
      called = true
      assert_equal HTTP::Status::BAD_REQUEST, status
    end
    assert called, "expected block to have been called"
  end

  private def call(public, path, headers = nil)
    context, io = new_context(headers)
    public.call(context, path)
    context.response.close
    HTTP::Client::Response.from_io(io.rewind)
  end

  private def new_context(headers = nil)
    request = HTTP::Request.new("GET", "/", headers)
    response = HTTP::Server::Response.new(io = IO::Memory.new)
    context = HTTP::Server::Context.new(request, response)
    {context, io}
  end
end
