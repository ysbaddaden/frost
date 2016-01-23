require "../test_helper"
require "http/request"
require "http/server/context"

module Frost::Routing
  abstract class RoutingTest < Minitest::Test
    def dispatch(method, url, headers = nil, body = nil)
      ctx = context_for(method, url, headers, body)
      dispatcher.dispatch(ctx)
      ctx.response
    end

    def context_for(method, url, headers = nil, body = nil)
      request = HTTP::Request.new(method, url, body: body)
      headers.each { |key, value| request.headers[key] = value } if headers
      response = HTTP::Server::Response.new(MemoryIO.new)
      HTTP::Server::Context.new(request, response)
    end

    abstract def dispatcher
  end
end
