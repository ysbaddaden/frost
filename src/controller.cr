require "http/server"
require "json"
require "mime"

# TODO: prevent double rendering
class Frost::Controller
  protected getter context : HTTP::Server::Context
  protected getter request : HTTP::Request
  protected getter response : HTTP::Server::Response
  protected getter params : Frost::Routes::Params

  def initialize(@context, @params)
    @request = @context.request
    @response = @context.response
  end

  protected def redirect_to(url : URI | String, status : HTTP::Status = :found) : Nil
    response.headers["location"] = url.to_s
    head status
  end

  protected def head(status : HTTP::Status) : Nil
    response.status = status
  end

  protected def render(*, plain text : String) : Nil
    response.headers["content-type"] = "text/plain; charset=utf-8"
    response << text
  end

  protected def render(*, html : String) : Nil
    response.headers["content-type"] = "text/html; charset=utf-8"
    response << html
  end

  protected def render(*, json contents) : Nil
    response.headers["content-type"] = "application/json; charset=utf-8"
    contents.to_json(response)
  end

  protected def send_data(contents : String | Bytes, *, filename = nil, disposition = "inline", type = nil) : Nil
    set_content_disposition(filename, disposition) if filename || disposition
    set_content_type(type, filename, default: "application/octet-stream")
    response << contents
  end

  protected def send_data(io : IO, *, filename = nil, disposition = "inline", type = nil) : Nil
    set_content_disposition(filename, disposition) if filename || disposition
    set_content_type(type, filename, default: "application/octet-stream")
    IO.copy(response)
  end

  protected def send_file(path : String | Path, *, filename = nil, disposition = "inline", type = nil) : Nil
    set_content_disposition(filename, disposition) if filename || disposition
    set_content_type(type, filename, default: "application/octet-stream")
    File.open(path) { |io| IO.copy(io, response) }
  end

  private def set_content_type(type, filename, default) : Nil
    if !type && filename
      type = File.extname(filename).presence
    end

    if mime = mime_type(type) || default
      response.headers["content-type"] = mime
    else
      raise ArgumentError.new("Unknown media type #{type}")
    end
  end

  private def mime_type(type : String)
    if type.includes?('/')
      type
    elsif type.starts_with?('.')
      MIME.from_extension?(type)
    else
      MIME.from_extension?(".#{type}")
    end
  end

  private def mime_type(type : Nil) : Nil
  end

  private def set_content_disposition(*, filename = nil, disposition = "attachment") : Nil
    response.headers["content-disposition"] =
      if filename
        content_disposition(filename, disposition)
      else
        disposition
      end
  end

  private def content_disposition(filename, disposition)
    String.build do |str|
      str << disposition

      if filename.ascii_only?
        str << "; filename=" << filename
      else
        str << "; filename*=UTF-8''"
        URI.encode_path_segment(str, filename)
      end
    end
  end
end
