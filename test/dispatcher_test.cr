require "http/server/context"
require "./test_helper"

module Frost
  class DispatcherTest < Minitest::Test
    module App
      class PagesController < Frost::Controller
        def success
          render text: "OK"
        end

        def failure
          raise "let's fail"
        end
      end

      {{ run "./fixtures/routes/dispatcher.cr", "--codegen" }}
    end

    def test_routes
      response = call("GET", "/success")
      assert_equal 200, response.status_code, response.body
      assert_equal "OK", response.body
    end

    def test_rescues_routing_errors
      response = call("GET", "/no/such/route")
      assert_equal 404, response.status_code
      assert_match "No route for GET \"/no/such/route\"", response.body
    end

    def test_rescues_exceptions
      response = call("GET", "/failure")
      #assert_equal 500, response.status_code
      assert_match "Exception: let's fail", response.body
    end

    def call(method, url)
      request = HTTP::Request.new(method, url)
      response = HTTP::Server::Response.new(io = MemoryIO.new)
      context = HTTP::Server::Context.new(request, response)

      dispatcher.call(context)
      response.flush

      io.rewind
      HTTP::Client::Response.from_io(io)
    end

    def dispatcher
      @dispatcher ||= App::Dispatcher.new
    end
  end
end
