require "./test_helper"

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
        super
      end
    end

    def test_filters
      controller = PagesController.new(HTTP::Request.new("GET", "/pages"), {} of String => String, "index")
      controller.run_action { controller.index }

      response = controller.response
      assert_equal "index", response.body

      assert_equal "pages:before", response.headers["X-Before"]
      assert_equal "pages:after", response.headers["X-After"]

      assert_equal "app:before", response.headers["X-Before-App"]
      assert_equal "app:after", response.headers["X-After-App"]
    end
  end
end
