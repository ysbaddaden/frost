require "./test_helper"

class Frost::ParamsTest < Minitest::Test
  def test_route
    params = Params.new(new_request, {
      "email" => "someone@domain.com",
      "password" => "secret",
    })
    assert_equal "someone@domain.com", params.route["email"]
    assert_equal "secret", params.route["password"]
  end

  def test_query
    params = Params.new(new_request(path: "/?email=someone%40domain.com&password=secret"), {} of String => String)
    assert_equal "someone@domain.com", params.query["email"]
    assert_equal "secret", params.query["password"]
  end

  def test_urlencoded_body
    request = new_request(body: "email=someone%40domain.com&password=secret", headers: HTTP::Headers{
      "content-type" => "application/x-www-form-urlencoded; charset=utf-8",
    })
    params = Params.new(request, {} of String => String)

    refute_nil params.body?
    assert_equal "someone@domain.com", params.body["email"]
    assert_equal "secret", params.body["password"]

    assert_nil params.files?
    assert_raises(ArgumentError) { params.files }
  end

  def test_multipart_body
    params = build_multipart_params do |form|
      form.field("name", "foo")

      File.open(__FILE__, "r") do |file|
        metadata = HTTP::FormData::FileMetadata.new(filename: "foo.txt")
        headers = HTTP::Headers{"content-type" => "text/plain"}
        form.file("file", file, metadata, headers)
      end
    end

    refute_nil params.body?
    assert_equal "foo", params.body["name"]

    refute_nil params.files?
    uploaded_file = params.files["file"]
    assert_equal "foo.txt", uploaded_file.original_filename
    assert_equal File.read(__FILE__), uploaded_file.to_io.gets_to_end
  end

  def test_multipart_parts_limit
    params = build_multipart_params do |form|
      1.upto(4096) { |index| form.field("name#{index}", "foo") }
    end
    refute_nil params.body
    assert_equal 4096, params.body.size

    params = build_multipart_params do |form|
      1.upto(4097) { |index| form.field("name#{index}", "foo") }
    end
    assert_raises(Params::MultipartLimit) { params.body }
  end

  def test_multipart_files_limit
    params = build_multipart_params do |form|
      headers = HTTP::Headers{"content-type" => "text/plain"}

      File.open(__FILE__, "r") do |file|
        1.upto(128) do |index|
          metadata = HTTP::FormData::FileMetadata.new(filename: "foo#{index}.txt")
          form.file("file", file, metadata, headers)
        end
      end
    end
    refute_nil params.files
    assert_equal 128, params.files.size

    params = build_multipart_params do |form|
      headers = HTTP::Headers{"content-type" => "text/plain"}

      File.open(__FILE__, "r") do |file|
        1.upto(129) do |index|
          metadata = HTTP::FormData::FileMetadata.new(filename: "foo#{index}.txt")
          form.file("file", file, metadata, headers)
        end
      end
    end
    assert_raises(Params::MultipartLimit) { params.files }
  end

  def test_body_with_unknown_content_type
    request = new_request(body: "{}", headers: HTTP::Headers{ "content-type" => "application/json; charset=utf-8" })
    params = Params.new(request, {} of String => String)

    assert_raises(ArgumentError) { params.body? }
    assert_raises(ArgumentError) { params.body }
    assert_raises(ArgumentError) { params.files? }
    assert_raises(ArgumentError) { params.files }
  end

  def test_no_request_body
    params = Params.new(new_request, {} of String => String)
    assert_nil params.body?
    assert_raises(ArgumentError) { params.body }
  end

  private def build_multipart_params(&)
    io, boundary = IO::Memory.new, MIME::Multipart.generate_boundary

    HTTP::FormData.build(io, boundary) do |form|
      yield form
    end

    request = new_request(body: io.rewind.to_s, headers: HTTP::Headers{
      "content-type" => "multipart/form-data; boundary=#{boundary}",
    })
    Params.new(request, {} of String => String)
  end

  private def new_request(path = "/", body = nil, headers = nil)
    request = HTTP::Request.new("GET", path, headers)
    request.body = body if body
    Frost::Request.new(request)
  end
end
