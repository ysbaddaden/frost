require "http/server/context"
require "./routes/params"
require "mime"

# Serve static files from a 'public' folder.
#
# ```
# Frost.draw_routes do
#   # ...
#
#   public = Frost::Public.new(Path.new(Dir.current, "public"))
#   get("/*path") { |ctx, params| public.call(ctx, params["path"]) }
# end
# ```
class Frost::Public
  getter public_path : Path
  property cache_control : String = "private, max-age=0, must-revalidate"
  property default_content_type = "application/octet-stream"

  def initialize(public_path : Path | String)
    @public_path = Path.new(public_path)
  end

  def call(context : HTTP::Server::Context, path : String) : Nil
    call(context, path) do |status|
      context.response.status = status
      context.response << status.code << ' ' << status.description
    end
  end

  def call(context : HTTP::Server::Context, path : String, & : HTTP::Status -> Nil) : Nil
    if invalid?(path)
      yield HTTP::Status::BAD_REQUEST
    else
      full_path = @public_path.join(path)
      if (info = File.info?(full_path)) && info.file?
        serve(context, full_path, info)
      else
        yield HTTP::Status::NOT_FOUND
      end
    end
    context.response.flush
  end

  # TODO: serve pre-compressed brotli and gzip files
  # TODO: set etag header (with cache)
  # TODO: support if-none-match header (with cache)
  private def serve(context, full_path, info) : Nil
    response = context.response

    # modification time has sub-second precision, but RFC 2822 only has second
    # precision, so we truncate the mtime to the second:
    mtime = info.modification_time.at_beginning_of_second

    if header = context.request.headers["if-modified-since"]?
      if Time.parse_rfc2822(header) >= mtime
        response.status = :not_modified
        return
      end
    end

    response.headers["content-length"] = info.size.to_s
    response.headers["content-type"] = MIME.from_extension(File.extname(full_path), default_content_type)
    response.headers["cache-control"] = @cache_control
    response.headers["last-modified"] = mtime.to_rfc2822

    File.open(full_path) { |file| IO.copy(file, response) }
  end

  private def invalid?(path : String) : Bool
    path.starts_with?('/') || path.starts_with?("../") || path.includes?("/../") || path.includes?('\0')
  end
end
