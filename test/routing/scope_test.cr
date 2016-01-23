require "./test_helper"

module Frost::Routing
  class ScopeTest < RoutingTest
    module App
      class PostsController < Frost::Controller
        def index
          render text: "posts#index"
        end
      end

      class Scoop::ThingsController < Frost::Controller
        def index
          render text: "scoop/things#index"
        end
      end

      class Admin::AuthorsController < Frost::Controller
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

    def dispatcher
      @dispatcher ||= App::Dispatcher.new
    end
  end
end
