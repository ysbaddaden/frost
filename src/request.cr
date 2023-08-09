require "http/server"

struct Frost::Request
  forward_missing_to @request

  def initialize(@request : HTTP::Request)
  end

  def xhr? : Bool
    if x_requested_with = @request.headers["x-requested-with"]?
      "xmlhttprequest".compare(x_requested_with, case_insensitive: true) == 0
    else
      false
    end
  end

  def content_type : String?
    @request.headers["content-type"]?
  end

  # Returns true if the request's content type is JSON (i.e. `application/json`)
  # or a derivate (e.g. `application/geo+json`).
  def json? : Bool
    content_type =~ %r{^application/(?:\w+\+|)json}
  end

  # Returns true if the request's content type is
  # `application/x-www-form-urlencoded`.
  def urlencoded? : Bool
    !!content_type.try(&.starts_with?("application/x-www-form-urlencoded"))
  end

  # Returns true if the request's content type is `multipart/form-data`.
  def multipart? : Bool
    !!content_type.try(&.starts_with?("multipart/form-data"))
  end
end
