require "http/server"
require "json"
require "mime"
require "./params"
require "./request"
require "./view"
require "./controller/callbacks"
require "./controller/session"

class Frost::Controller
  class DoubleRenderError < Exception
  end

  include Controller::Callbacks
  include Controller::Session

  getter context : HTTP::Server::Context
  getter request : Request
  getter response : HTTP::Server::Response
  getter params : Params
  getter action_name : String

  def initialize(@context, route_params : Routes::Params, @action_name)
    @request = Request.new(@context.request)
    @response = @context.response
    @params = Params.new(@request, route_params)
    @__rendered = false
  end

  def redirect_to(url : URI | String, status : HTTP::Status = :see_other) : Nil
    response.headers["location"] = url.to_s
    head status
  end

  def head(status : HTTP::Status) : Nil
    prevent_double_rendering!
    response.status = status
  end

  def render(view : View, *, status : HTTP::Status = :ok) : Nil
    prevent_double_rendering!
    response.status = status
    response.headers["content-type"] = view.content_type
    view.render(response)
  end

  def render(*, plain text : String, status : HTTP::Status = :ok) : Nil
    prevent_double_rendering!
    response.status = status
    response.headers["content-type"] = "text/plain; charset=utf-8"
    response << text
  end

  def render(*, html : String, status : HTTP::Status = :ok) : Nil
    prevent_double_rendering!
    response.status = status
    response.headers["content-type"] = "text/html; charset=utf-8"
    response << html
  end

  def render(*, json contents, status : HTTP::Status = :ok) : Nil
    prevent_double_rendering!
    response.status = status
    response.headers["content-type"] = "application/json; charset=utf-8"
    contents.to_json(response)
  end

  def send_data(contents : String | Bytes, *, filename = nil, disposition = "inline", type = nil, status : HTTP::Status = :ok) : Nil
    prevent_double_rendering!
    response.status = status
    set_content_disposition(filename, disposition) if filename || disposition
    set_content_type(type, filename, default: "application/octet-stream")
    response.write(contents.to_slice)
  end

  def send_data(io : IO, *, filename = nil, disposition = "inline", type = nil, status : HTTP::Status = :ok) : Nil
    prevent_double_rendering!
    response.status = status
    set_content_disposition(filename, disposition) if filename || disposition
    set_content_type(type, filename, default: "application/octet-stream")
    IO.copy(io, response)
  end

  def send_file(path : String | Path, *, filename = nil, disposition = "inline", type = nil, status : HTTP::Status = :ok) : Nil
    filename ||= File.basename(path)

    File.open(path) do |io|
      send_data io, filename: filename, disposition: disposition, type: type, status: status
    end
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

  private def set_content_disposition(filename = nil, disposition = "attachment") : Nil
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

  # :nodoc:
  def prevent_double_rendering! : Nil
    if @__rendered
      raise DoubleRenderError.new("Render and/or redirect were called multiple times for this action")
    else
      @__rendered = true
    end
  end

  def already_rendered? : Bool
    @__rendered
  end
end
