require "./test_helper"
require "http/server/context"

module Frost
  class ControllerTest < Minitest::Test
    class AppController < Frost::Controller
      def before_action
        response.headers["X-Before-App"] = "app:before"
      end

      def after_action
        response.headers["X-After-App"] = "app:after"
      end
    end

    class PagesController < AppController
      def index
        render text: "index"
      end

      def before_action
        super
        response.headers["X-Before"] = "pages:before"
      end

      def after_action
        response.headers["X-After"] = "pages:after"
        response.body = "#{response.body} (with after filter)"
        super
      end
    end

    def test_run_action
      io = MemoryIO.new
      ctx = HTTP::Server::Context.new(HTTP::Request.new("GET", "/pages"), HTTP::Server::Response.new(io))
      controller = PagesController.new(ctx, {} of String => String, "index")

      # run action
      controller.run_action { controller.index }
      controller.response.close

      # parse response
      io.rewind
      response = HTTP::Client::Response.from_io(io)

      # rendered body (altered in after filter)
      assert_nil response.headers["Content-Length"]?
      assert_equal "index (with after filter)", response.body

      # executed before filters
      assert_equal "pages:before", response.headers["X-Before"]
      assert_equal "app:before", response.headers["X-Before-App"]

      # executed after filters
      assert_equal "pages:after", response.headers["X-After"]
      assert_equal "app:after", response.headers["X-After-App"]
    end

  end
end
