require "./request"
require "./routes/params"
require "./params/*"

struct Frost::Params
  @body : URI::Params?
  @files : UploadedFiles?

  # :nodoc:
  def initialize(@request : Request, @route : Routes::Params)
  end

  # Accessor to params parsed from the URI path by the router.
  @[AlwaysInline]
  def route : Routes::Params
    @route
  end

  # Accessor to params parsed from the URI query string.
  @[AlwaysInline]
  def query : URI::Params
    @request.query_params
  end

  # Accessor to params parsed from the body (if any). Only the
  # `application/x-www-form-urlencoded` and `multipart/form-data` content types
  # are supported. Other types (e.g. JSON) should be parsed manually.
  @[AlwaysInline]
  def body : URI::Params
    body? || raise ArgumentError.new("Request doesn't have a body")
  end

  @[AlwaysInline]
  def body? : URI::Params?
    @body || begin
               parse_request_body
               @body
             end
  end

  # Accessor to files parsed from the request body for the `multipart/form-data`
  # content type only.
  @[AlwaysInline]
  def files : UploadedFiles
    files? || raise ArgumentError.new("Request doesn't have a body")
  end

  @[AlwaysInline]
  def files? : UploadedFiles?
    @files || begin
                parse_request_body unless @body
                @files
              end
  end

  private def parse_request_body : Nil
    return unless body = @request.body

    if @request.urlencoded?
      @body = URI::Params.parse(body.gets_to_end)
    elsif @request.multipart?
      parse_multipart_request_body
    else
      raise ArgumentError.new("Unsupported content-type: #{@request.headers["content-type"]?.inspect}")
    end
  end

  @[AlwaysInline]
  private def parse_multipart_request_body : Nil
    params, files = URI::Params.new, UploadedFiles.new

    HTTP::FormData.parse(@request.@request) do |part|
      if part.filename
        files.add(part.name, UploadedFile.new(part))
      else
        params.add(part.name, part.body.gets_to_end)
      end
    end

    @body, @files = params, files
  end

  @[AlwaysInline]
  def format : String?
    @route["format"]?
  end

  def close : Nil
    return unless uploaded_files = @files

    uploaded_files.each do |_, uploaded_file|
      uploaded_file.close unless uploaded_file.closed?

      {% unless flag?(:unix) %}
        uploaded_file.delete
      {% end %}
    end
  end
end
