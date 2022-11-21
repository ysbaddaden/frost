require "http/server"
require "json"
require "mime"
require "./request"
require "./view"
require "./controller/callbacks"
require "./controller/session"

class Frost::Controller
  class DoubleRenderError < Exception
  end

  include Frost::Controller::Callbacks
  include Frost::Controller::Session

  getter context : HTTP::Server::Context
  getter request : Frost::Request
  getter response : HTTP::Server::Response
  getter params : Frost::Routes::Params
  getter action_name : String

  def initialize(@context, @params, @action_name)
    @request = Frost::Request.new(@context.request, @params)
    @response = @context.response
    @__rendered = false
  end

  def redirect_to(url : URI | String, status : HTTP::Status = :found) : Nil
    response.headers["location"] = url.to_s
    head status
  end

  def head(status : HTTP::Status) : Nil
    prevent_double_rendering!
    response.status = status
  end

  private macro render(action, status = :ok, layout = nil)
    {% unless action.is_a?(SymbolLiteral) || action.is_a?(StringLiteral) %}
      {% raise "action must be a symbol or string literal" %}
    {% end %}

    prevent_double_rendering!
    response.status = HTTP::Status.new({{status}})
    __render self, {{action}}, {{layout}}
  end

  private macro render(status = :ok, layout = nil)
    render \{{@def.name.id.symbolize}}, {{status}}, {{layout}}
  end

  # :nodoc:
  macro default_render(controller, action)
    {% unless action.is_a?(SymbolLiteral) || action.is_a?(StringLiteral) %}
      {% raise "action must be a symbol or string literal" %}
    {% end %}

    unless {{controller}}.@__rendered
      if {{controller}}.template_exists?({{action}})
        # the template exists: render it
        {{controller}}.prevent_double_rendering!
        {{@type}}.__render {{controller}}, {{action}}
      else
        %request = {{controller}}.request

        # render default template for browser GET requests (unless XHR):
        if %request.method == "GET" && %request.format == "html" && !%request.xhr?
          {{controller}}.prevent_double_rendering!
          {{@type}}.__render {{controller}}, {{action}}
        end
      end

      # fallback to a 204 No Content response
      unless {{controller}}.@__rendered
        {{controller}}.head :no_content
      end
    end
  end

  def template_exists?(action) : Bool
    {{ @type.name.gsub(/Controller$/, "View").id }}
      .template_exists?(action, request.format)
  end

  # :nodoc:
  macro __render(controller, action, layout = nil)
    %view_class = {{@type.name.gsub(/Controller$/, "View")}}
    %view = %view_class.new({{controller}})

    %format = {{controller}}.request.format

    if {{layout}} == false
      %view.{{action.id}}(%format)
    else
      %view.layout({{layout}} || "application", %format) do
        %view.{{action.id}}(%format)
      end
    end

    nil
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
