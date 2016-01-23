require "http/server"

# Redirects any HTTP request on be HTTPS instead.
#
# This handler requires that the `X-Forwarded-Proto` header to be set to
# distinguish whether the request was over `http` or `https`. Heroku does
# provide it for instance. If the header is missing, no check nor redirection
# will be attempted.
#
# The redirection will be a 308 Permanent Redirect HTTP response, so browsers
# are told to reissue the request permanently and to use the same HTTP method
# (eg: POST or DELETE) over HTTPS.
abstract class Frost::Server
  class HttpsEverywhereHandler < HTTP::Handler
    getter :status_code

    def initialize(@status_code = 308)
    end

    def call(ctx)
      if proto = ctx.request.headers["X-Forwarded-Proto"]?
        return redirect_to_https(ctx) if proto != "https"
      end
      call_next(ctx)
    end

    def redirect_to_https(ctx)
      ctx.response.headers["Location"] =
        "https://#{ ctx.request.headers["Host"] }#{ ctx.request.resource }"
      nil
    end
  end
end
