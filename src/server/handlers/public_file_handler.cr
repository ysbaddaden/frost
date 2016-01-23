require "http/server"
require "openssl/digest"

abstract class Frost::Server
  class PublicFileHandler < HTTP::Handler
    # TODO: set cache-control headers
    # OPTIMIZE: cache & serve already deflated files
    # OPTIMIZE: memoize etags

    def initialize(@publicdir)
    end

    def call(ctx)
      path = local_path(ctx.request)

      if path.includes?('\0')
        # protect against file traversal
        ctx.response.status_code = 400
        return
      end

      unless public_file?(path)
        return call_next(ctx)
      end

      contents = File.read(path)
      etag = digest(contents)
      response = ctx.response

      response.headers["Content-Type"] = mime_type(path)
      response.headers["Etag"] = etag

      if ctx.request.headers["If-None-Match"]? == etag
        response.status_code = 304
      else
        response.status_code = 200
        response << contents
      end

      nil
    end

    private def local_path(ctx)
      path = URI.unescape(ctx.path)

      # protect against directory traversal
      expanded_path = File.expand_path(path, "/")

      File.join(@publicdir, expanded_path)
    end

    private def public_file?(path)
      File.exists?(path) && !File.directory?(path)
    end

    private def mime_type(path)
      Frost::Support::Mime.mime_type(File.extname(path))
    end

    private def digest(contents)
      digest = OpenSSL::Digest.new("MD5")
      digest.update(contents)
      digest.hexdigest
    end
  end
end
