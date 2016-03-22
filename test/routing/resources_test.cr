require "./test_helper"

module Frost::Routing
  # TODO: test named routes
  class ResourcesTest < RoutingTest
    module App
      class PostsController < Frost::Controller
        {% for action in %w(index show new edit create update replace destroy
                            search publish) %}
          def {{ action.id }}
            args = params.map { |k, v| "#{k}:#{v}" }.compact
            render text: "#{request.method}: posts##{ action_name } (#{ args.join(", ") })"
          end
        {% end %}
      end

      class CommentsController < Frost::Controller
        {% for action in %w(index show new edit create update replace destroy) %}
          def {{ action.id }}
            args = params.map { |k, v| "#{k}:#{v}" }.compact
            render text: "#{request.method}: comments##{ action_name } (#{ args.join(", ") })"
          end
        {% end %}
      end

      class UsersController < Frost::Controller
        {% for action in %w(show new edit create update replace destroy posts) %}
          def {{ action.id }}
            args = params.map { |k, v| "#{k}:#{v}" }.compact
            render text: "#{request.method}: users##{ action_name } (#{ args.join(", ") })"
          end
        {% end %}
      end

      class Rs1sController < Frost::Controller
        def index; head 200; end
      end

      class Rs2sController < Frost::Controller
        def show; head 200; end
      end

      class Rs3sController < Frost::Controller
        def new; head 200; end
        def edit; head 200; end
      end

      class Rs4sController < Frost::Controller
        def create; head 200; end
        def update; head 200; end
        def replace; head 200; end
        def destroy; head 200; end
      end

      class R1sController < Frost::Controller
        def replace; head 200; end
      end

      class R2sController < Frost::Controller
        def show; head 200; end
      end

      class R3sController < Frost::Controller
        def new; head 200; end
        def edit; head 200; end
      end

      class R4sController < Frost::Controller
        def create; head 200; end
        def update; head 200; end
        def destroy; head 200; end
      end

      {{ run "../fixtures/routes/resources.cr", "--codegen" }}
    end

    def test_resources
      assert_equal "GET: posts#index ()", dispatch("GET", "/posts").body
      assert_equal "GET: posts#show (id:1)", dispatch("GET", "/posts/1").body
      assert_equal "GET: posts#new ()", dispatch("GET", "/posts/new").body
      assert_equal "GET: posts#edit (id:1)", dispatch("GET", "/posts/1/edit").body
      assert_equal "PATCH: posts#update (id:1)", dispatch("PATCH", "/posts/1").body
      assert_equal "PUT: posts#replace (id:1)", dispatch("PUT", "/posts/1").body
      assert_equal "DELETE: posts#destroy (id:1)", dispatch("DELETE", "/posts/1").body
    end

    def test_resources_format
      assert_equal "GET: posts#index (format:html)", dispatch("GET", "/posts.html").body
      assert_equal "GET: posts#show (id:1, format:json)", dispatch("GET", "/posts/1.json").body
      assert_equal "GET: posts#new (format:xml)", dispatch("GET", "/posts/new.xml").body
      assert_equal "GET: posts#edit (id:1, format:html)", dispatch("GET", "/posts/1/edit.html").body
      assert_equal "PATCH: posts#update (id:1, format:yml)", dispatch("PATCH", "/posts/1.yml").body
      assert_equal "PUT: posts#replace (id:1, format:csv)", dispatch("PUT", "/posts/1.csv").body
      assert_equal "DELETE: posts#destroy (id:1, format:xls)", dispatch("DELETE", "/posts/1.xls").body
    end

    def test_resource
      assert_equal "GET: users#show ()", dispatch("GET", "/user").body
      assert_equal "GET: users#new ()", dispatch("GET", "/user/new").body
      assert_equal "GET: users#edit ()", dispatch("GET", "/user/edit").body
      assert_equal "PATCH: users#update ()", dispatch("PATCH", "/user").body
      assert_equal "PUT: users#replace ()", dispatch("PUT", "/user").body
      assert_equal "DELETE: users#destroy ()", dispatch("DELETE", "/user").body
    end

    def test_resource_format
      assert_equal "GET: users#show (format:json)", dispatch("GET", "/user.json").body
      assert_equal "GET: users#new (format:xml)", dispatch("GET", "/user/new.xml").body
      assert_equal "GET: users#edit (format:html)", dispatch("GET", "/user/edit.html").body
      assert_equal "PATCH: users#update (format:yml)", dispatch("PATCH", "/user.yml").body
      assert_equal "PUT: users#replace (format:csv)", dispatch("PUT", "/user.csv").body
      assert_equal "DELETE: users#destroy (format:xls)", dispatch("DELETE", "/user.xls").body
    end

    def test_only_resources_actions_with_symbol
      dispatch("GET", "/rs1s")
      assert_raises(RoutingError) { dispatch("GET", "/rs1s/new") }
      assert_raises(RoutingError) { dispatch("GET", "/rs1s/edit") }
      assert_raises(RoutingError) { dispatch("POST", "/rs1s") }
      assert_raises(RoutingError) { dispatch("PATCH", "/rs1s") }
      assert_raises(RoutingError) { dispatch("PUT", "/rs1s") }
      assert_raises(RoutingError) { dispatch("DELETE", "/rs1s") }
    end

    def test_only_resources_actions_with_string
      assert_raises(RoutingError) { dispatch("GET", "/rs2s") }
      dispatch("GET", "/rs2s/1")

      # NOTE: the following matches the #show action where id="new"
      dispatch("GET", "/rs2s/new")

      assert_raises(RoutingError) { dispatch("GET", "/rs2s/1/edit") }
      assert_raises(RoutingError) { dispatch("POST", "/rs2s") }
      assert_raises(RoutingError) { dispatch("PATCH", "/rs2s/1") }
      assert_raises(RoutingError) { dispatch("PUT", "/rs2s/1") }
      assert_raises(RoutingError) { dispatch("DELETE", "/rs2s/1") }
    end

    def test_only_resources_actions_with_array_of_symbols
      assert_raises(RoutingError) { dispatch("GET", "/rs3s") }
      assert_raises(RoutingError) { dispatch("GET", "/rs3s/1") }
      dispatch("GET", "/rs3s/new")
      dispatch("GET", "/rs3s/1/edit")
      assert_raises(RoutingError) { dispatch("POST", "/rs3s") }
      assert_raises(RoutingError) { dispatch("PATCH", "/rs3s/1") }
      assert_raises(RoutingError) { dispatch("PUT", "/rs3s/1") }
      assert_raises(RoutingError) { dispatch("DELETE", "/rs3s/1") }
    end

    def test_only_resources_actions_with_array_of_strings
      assert_raises(RoutingError) { dispatch("GET", "/rs4s") }
      assert_raises(RoutingError) { dispatch("GET", "/rs4s/1") }
      assert_raises(RoutingError) { dispatch("GET", "/rs4s/new") }
      assert_raises(RoutingError) { dispatch("GET", "/rs4s/1/edit") }
      dispatch("POST", "/rs4s")
      dispatch("PATCH", "/rs4s/1")
      dispatch("PUT", "/rs4s/1")
      dispatch("DELETE", "/rs4s/1")
    end

    def test_only_resource_actions_with_symbol
      assert_raises(RoutingError) { dispatch("GET", "/r1") }
      assert_raises(RoutingError) { dispatch("GET", "/r1/new") }
      assert_raises(RoutingError) { dispatch("GET", "/r1/edit") }
      assert_raises(RoutingError) { dispatch("POST", "/r1") }
      assert_raises(RoutingError) { dispatch("PATCH", "/r1") }
      dispatch("PUT", "/r1")
      assert_raises(RoutingError) { dispatch("DELETE", "/r1") }
    end

    def test_only_resource_actions_with_string
      dispatch("GET", "/r2")
      assert_raises(RoutingError) { dispatch("GET", "/r2/new") }
      assert_raises(RoutingError) { dispatch("GET", "/r2/edit") }
      assert_raises(RoutingError) { dispatch("POST", "/r2") }
      assert_raises(RoutingError) { dispatch("PATCH", "/r2") }
      assert_raises(RoutingError) { dispatch("PUT", "/r2") }
      assert_raises(RoutingError) { dispatch("DELETE", "/r2") }
    end

    def test_only_resource_actions_with_array_of_symbols
      assert_raises(RoutingError) { dispatch("GET", "/r3") }
      dispatch("GET", "/r3/new")
      dispatch("GET", "/r3/edit")
      assert_raises(RoutingError) { dispatch("POST", "/r3") }
      assert_raises(RoutingError) { dispatch("PATCH", "/r3") }
      assert_raises(RoutingError) { dispatch("PUT", "/r3") }
      assert_raises(RoutingError) { dispatch("DELETE", "/r3") }
    end

    def test_only_resource_actions_with_array_of_strings
      assert_raises(RoutingError) { dispatch("GET", "/r4") }
      assert_raises(RoutingError) { dispatch("GET", "/r4/new") }
      assert_raises(RoutingError) { dispatch("GET", "/r4/edit") }
      dispatch("POST", "/r4")
      dispatch("PATCH", "/r4")
      assert_raises(RoutingError) { dispatch("PUT", "/r4") }
      dispatch("DELETE", "/r4")
    end

    def test_nested_resources
      assert_equal "GET: comments#index (post_id:1)",
        dispatch("GET", "/posts/1/comments").body

      assert_equal "DELETE: comments#destroy (post_id:123, id:456, format:json)",
        dispatch("DELETE", "/posts/123/comments/456.json").body

      assert_equal "GET: users#show (post_id:1, format:html)",
        dispatch("GET", "/posts/1/user.html").body

      assert_equal "GET: comments#index ()",
        dispatch("GET", "/user/comments").body

      assert_equal "GET: comments#show (id:5)",
        dispatch("GET", "/user/comments/5").body
    end

    def test_member
      assert_equal "POST: posts#publish (id:1)",
        dispatch("POST", "/posts/1/publish").body

      assert_equal "GET: users#posts ()",
        dispatch("GET", "/user/posts").body
    end

    def test_collection
      assert_equal "GET: posts#search ()",
        dispatch("GET", "/posts/search").body
    end

    def dispatcher
      @dispatcher ||= App::Dispatcher.new
    end
  end
end
