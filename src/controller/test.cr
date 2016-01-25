require "http/server/context"
require "../support/core_ext/http/headers"
require "./assertions"
require "./session/test_store"

module Frost
  abstract class Controller
    module Session
      def session_store
        TestStore
      end
    end

    # Unit tests your routes and controllers. This actually tests your
    # `Dispatcher`, using forged `HTTP::Request` objects, and not your
    # controllers directly using test requests. In this sense, this can be
    # considered to be somewhere between unit and integration tests.
    #
    # To make a request use the `#get`, `#head`, `#options`, `#post`, `#put`,
    # `#patch` and `#delete` methods. For example:
    #
    # ```
    # get "/posts"
    # post "/users", "name=julien&password=secret"
    # delete "/users/1"
    # ```
    #
    # After making a request, you may test the `#response` HTTP::Client::Response
    # object. See `Assertions` for some helpers.
    #
    # ## Host
    #
    # The `Host` header will be set to `test.host` by default, unless the header
    # is provided, or the URL contains a host. For example:
    #
    # ```
    # get "/posts"                               # => Host: test.host
    # get "/posts", { "Host" => "example.com" }  # => Host: example.com
    # get "http://example.org/posts"             # => Host: example.org
    # ```
    #
    # ## Body
    #
    # The body for POST, PUT and PATCH requests is considered to have been
    # serialized with `application/x-www-form-urlencoded` by default, but can be
    # serialized as XML or JSON, as long as the correct `Content-Type` header is
    # defined. For example:
    #
    # ```
    # put "/posts/1", "title=hello%20world"
    #
    # patch "/posts/1", { title: "hello world" }.to_json, {
    #   "Content-Type" => "application/json"
    # }
    # ```
    #
    # ## Basic Authorization
    #
    # If provided, the userinfo will be used for a Basic HTTP Authorization
    # (Base64 encoded), filling the `Authorization` header. For example:
    #
    # ```
    # get "/api/users/api_key.json", userinfo: "julien:secret"
    # ```
    #
    # ## Sessions
    #
    # The `#session` object can be accessed before and after making requests to
    # manipulate the session date (eg: log a user in) or to run assertions
    # againsts it (eg: to verify a user was logged in).
    #
    # The session object will be resetted between each test.
    class Test < Minitest::Test
      # TODO: include named route helpers

      include Assertions

      getter! :response

      # Returns the `Dispatcher` instance to issue requests on. Defaults to
      # `Frost.application`.
      def dispatcher
        raise ArgumentError.new("You must specify a dispatcher to run tests against")
      end

      # Returns the session object to be manipulated before a request, or to run
      # assertions after a request.
      def session
        @session ||= {} of String => String
      end

      # :nodoc:
      def after_teardown
        Session::TestStore.reset
        @session = nil
        super
      end

      {% for method in %w(options head get delete) %}
        def {{ method.id }}(uri, headers = nil, userinfo = nil)
          url = URI.parse(uri)
          path = url.path || "/"
          path += "?#{url.query}" if url.query

          request = HTTP::Request.new({{ method.upcase }}, path, headers: HTTP::Headers.from(headers))
          request.headers["Host"] ||= url.host || "test.host"

          execute_request(request, userinfo)
        end
      {% end %}

      {% for method in %w(post put patch) %}
        # Issues a {{ method.upcase }} request, with a String body.
        def {{ method.id }}(uri, body = nil : String, headers = nil, userinfo = nil)
          url = URI.parse(uri)
          path = url.path || "/"
          path += "?#{url.query}" if url.query

          request = HTTP::Request.new({{ method.upcase }}, path, headers: HTTP::Headers.from(headers), body: body.to_s)
          request.headers["Host"] ||= url.host || "test.host"
          request.headers["Content-Type"] ||= "application/x-www-form-urlencoded"

          execute_request(request, userinfo)
        end

        # TODO: encode Hash params as application/x-www-form-urlencoded
        #def {{ method.id }}(path, params : Hash, headers = nil, userinfo = nil)
        #  body = ""
        #
        #  headers ||= HTTP::Headers.from(headers)
        #  headers["Content-Type"] = "application/x-www-form-urlencoded"
        #
        #  {{ method.id }}(path, body, headers)
        #end
      {% end %}

      private def execute_request(request, userinfo)
        http_io = MemoryIO.new
        http_response = HTTP::Server::Response.new(http_io)
        context = HTTP::Server::Context.new(request, http_response)

        if @session
          Session::TestStore.new(request, context.response).set_data(session)
        end

        if userinfo
          request.headers["Authorization"] = "Basic #{Base64.encode(userinfo)}"
        end

        controller = dispatcher.dispatch(context)
        @response = controller.response

        @session = Session::TestStore.new(controller.response).read
        nil
      end
    end
  end
end
