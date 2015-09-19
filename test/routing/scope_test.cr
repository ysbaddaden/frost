require "../test_helper"
require "http/request"

module Trail::Routing
  class ScopeTest < Minitest::Test
    module App
      class PostsController < Trail::Controller
        def index
          render text: "posts#index"
        end
      end

      class Scoop::ThingsController < Trail::Controller
        def index
          render text: "scoop/things#index"
        end
      end

      class Admin::AuthorsController < Trail::Controller
        def index
          render text: "admin/authors#index"
        end
      end

      {{ run "../fixtures/routes/scope.cr", "--codegen" }}
    end

    def test_scope_path
      assert_equal "posts#index",
        dispatch("GET", "/scoop/posts").body
    end

    def test_scope_name
      assert_equal "scoop/things#index",
        dispatch("GET", "/things").body
    end

    def test_namespace
      assert_equal "admin/authors#index",
        dispatch("GET", "/admin/authors").body
    end

    def dispatch(method, url)
      dispatcher.dispatch(HTTP::Request.new(method, url))
    end

    def dispatcher
      @app ||= App::Dispatcher.new
    end
  end
end
