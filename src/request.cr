require "http/server"

struct Frost::Request
  forward_missing_to @request

  def initialize(@request : HTTP::Request)
  end

  # Returns true if the request originates from a XMLHttpRequest call. You'll
  # have to set the `x-requested-with: xmlhttprequest` header yourself.
  def xhr? : Bool
    if x_requested_with = @request.headers["x-requested-with"]?
      "xmlhttprequest".compare(x_requested_with, case_insensitive: true) == 0
    else
      false
    end
  end

  # Returns the content-type of the request's body.
  def content_type : String?
    @request.headers["content-type"]?
  end

  # Returns true if the request's body content type is JSON (i.e. `application/json`)
  # or a derivate (e.g. `application/geo+json`).
  def json? : Bool
    !!(content_type =~ %r{^application/(?:\w+\+|)json})
  end

  # Returns true if the request's body content type is an urlencoded form
  # (`application/x-www-form-urlencoded`).
  def urlencoded? : Bool
    !!content_type.try(&.starts_with?("application/x-www-form-urlencoded"))
  end

  # Returns true if the request's body content type is a multipart form
  # (`multipart/form-data`).
  def multipart? : Bool
    !!content_type.try(&.starts_with?("multipart/form-data"))
  end

  # Returns true if the request's `accept` header includes the given mimetype.
  #
  # For example: `request.accept?("text/event-stream")`
  def accept?(mime : String) : Bool
    if header = @request.headers["accept"]?
      return true if header == mime

      header.split(',') do |accept|
        accept = accept.strip

        return true if accept == mime
        return true if accept.includes?("*/*")

        if index = accept.index("/*")
          return true if mime.to_slice[0..index] == accept.to_slice[0..index]
        end

        if index = accept.index(';')
          return true if mime.to_slice == accept.to_slice[0...index]
        end
      end
    end

    false
  end
end
