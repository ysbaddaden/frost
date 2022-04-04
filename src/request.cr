require "http/server"

struct Frost::Request
  forward_missing_to @request

  def initialize(@request : HTTP::Request, @params : Frost::Routes::Params)
  end

  def xhr? : Bool
    if x_requested_with = @request.headers["x-requested-with"]?
      "xmlhttprequest".compare(x_requested_with, case_insensitive: true) == 0
    else
      false
    end
  end

  def format
    # TODO: extract format from `accept` header then default to "html"
    @params["format"]? || "html"
  end
end
