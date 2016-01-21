require "http/server"
require "openssl/digest"

module Frost::Server
  class PublicFileHandler < HTTP::Handler
    # TODO: set cache-control headers
    # OPTIMIZE: cache & serve already deflated files
    # OPTIMIZE: memoize etags

    def initialize(@publicdir)
    end

    def call(request)
      path = local_path(request)
      return HTTP::Response.new(400) if path.includes?('\0') # protect against file traversal
      return call_next(request) unless public_file?(path)

      contents = File.read(path)
      etag = digest(contents)

      headers = HTTP::Headers{
        "Content-Type": mime_type(path),
        "Etag": etag,
      }

      if request.headers["If-None-Match"]? == etag
        HTTP::Response.new(304, nil, headers)
      else
        HTTP::Response.new(200, contents, headers)
      end
    end

    private def local_path(request)
      path = URI.unescape(request.path)
      expanded_path = File.expand_path(path, "/") # protect against directory traversal
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
