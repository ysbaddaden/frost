require "./test_helper"

module Trail
  class ControllerTest < Minitest::Test
    class AppController < Trail::Controller
      before_action :app_before
      around_action :app_around
      after_action :app_after

      def app_before
        response.headers["X-Before-App"] = "app:before"
      end

      def app_around
        response.headers["X-Around-App"] = "app:around:before"
        yield
        response.headers["X-Around-App"] += ", app:around:after"
      end

      def app_after
        response.headers["X-After-App"] = "app:after"
      end
    end

    class PagesController < AppController
      before_action :before
      around_action :around
      after_action :after

      def index
        render text: "index"
      end

      def before
        response.headers["X-Before"] = "pages:before"
      end

      def around
        response.headers["X-Around"] = "pages:around:before"
        yield
        response.headers["X-Around"] += ", pages:around:after"
      end

      def after
        response.headers["X-After"] = "pages:after"
      end
    end

    def test_filters
      controller = PagesController.new(HTTP::Request.new("GET", "/pages"), {} of String => String, "index")
      controller.run_action { controller.index }

      response = controller.response
      assert_equal "index", response.body

      assert_equal "pages:before", response.headers["X-Before"]
      assert_equal "pages:after", response.headers["X-After"]
      assert_equal "pages:around:before, pages:around:after", response.headers["X-Around"]

      assert_equal "app:before", response.headers["X-Before-App"]
      assert_equal "app:after", response.headers["X-After-App"]
      assert_equal "app:around:before, app:around:after", response.headers["X-Around-App"]
    end
  end
end
