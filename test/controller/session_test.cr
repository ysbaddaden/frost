require "../test_helper"
require "http/server/context"

module Frost
  class ControllerTest < Minitest::Test
    class AppController < Frost::Controller
      def create
        session["calls"] = 0
        head 200
      end

      def read
        render text: session["calls"]?.to_s
        if session["calls"]?
          session["calls"] = session["calls"].to_i + 1
        end
      end

      def destroy
        session.destroy
        render text: session["calls"]?.to_s
      end

      def no_session
        head :ok
      end

      def session_enabled?
        action_name != "no_session"
      end
    end

    def params
      {} of String => String
    end

    macro run(action, cookie = nil)
      %request = HTTP::Request.new("GET", "/")
      {% if cookie %}
        %request.cookies << {{ cookie }}
      {% end %}

      %response = HTTP::Server::Response.new(MemoryIO.new)
      %context = HTTP::Server::Context.new(%request, %response)

      %controller = AppController.new(%context, {} of String => String, {{ action }})
      %controller.run_action { %controller.{{ action.id }} }

      %context.response
    end

    def test_session_lifetime
      # new session
      response = run("create")
      assert cookie = response.cookies["_session"]

      response = run("read", cookie)
      assert cookie = response.cookies["_session"]
      assert_equal "0", response.body

      response = run("read", cookie)
      assert cookie = response.cookies["_session"]
      assert_equal "1", response.body

      # new session
      response = run("destroy", cookie)
      assert cookie = response.cookies["_session"]

      response = run("read", cookie)
      assert cookie = response.cookies["_session"]
      assert_empty response.body
    end

    def test_session_enabled
      response = run("no_session")
      refute response.cookies["_session"]?
    end
  end
end
