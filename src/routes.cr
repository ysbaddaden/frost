require "./support/inflections"
require "./routes/handler"
require "./controller"

module Frost
  # The `HTTP::Handler` to use for the HTTP::Server or Earl::HTTPServer. It
  # should be the last middleware in the list.
  def self.handler : Routes::Handler
    @@handler ||= Routes::Handler.new
  end

  # Declare your application's routes.
  def self.draw_routes
    with Frost::Routes yield Frost::Routes
  end

  module Routes
    # nodoc
    CONTROLLER_SCOPE = [] of String

    # nodoc
    NAMESPACE_SCOPE = [] of String

    # nodoc
    @@current_path : String?

    # nodoc
    @@current_collection_path : String?

    # nodoc
    @@current_member_path : String?

    # Scope a set of routes to use the specified controller.
    #
    # ```
    # controller PostsController do
    #  get "/posts", :index     # GET /posts     => PostsController#index
    #  get "/posts/:id", :show  # GET /posts/:id => PostsController#show
    # end
    # ```
    macro controller(klass)
      # Crystal-macros-fu:
      #
      # We need two inner macros: the first will set the controller and evaluate
      # the block, the second will reset the scope. This is required for the
      # block to access the specified controller: if we manipulated the scope
      # without inner macros, then crystal would execute all available macros
      # _before_ evaluating the macro block, i.e. push the controller, reset the
      # controller and only then evaluate the block (oops).
      with_controller({{klass}}) do
        {{yield}}
      end

      # If you understood the previous comment, you'll understand that `.last`
      # is resolved _before_ evaluating `with_controller` hence returns the
      # *current* controller.
      reset_controller({{Frost::Routes::CONTROLLER_SCOPE.last}})
    end

    private macro with_controller(klass)
      {% Frost::Routes::CONTROLLER_SCOPE << klass %}
      {{yield}}
    end

    private macro reset_controller(klass)
      # There is no ArrayLiteral#pop, so we must push the previous value *again*
      {% Frost::Routes::CONTROLLER_SCOPE << klass %}
    end

    # Scope a set of routes under a parent path.
    #
    # ```
    # path "/posts" do
    #  get "", PostsController, :index   # GET /posts     => PostsController#index
    #  get ":id", PostsController, :show # GET /posts/:id => PostsController#show
    # end
    # ```
    #
    # You can nest calls, each one adding a new segment to the parent path:
    #
    # ```
    # path :api do
    #   path :v1 do
    #     get "posts", PostsController, :index # GET /api/v1/posts => PostsController#index
    #   end
    # end
    def self.path(path : String)
      with_absolute_path(join_path(path)) { yield }
    end

    # Replaces the current path. Restores the current path after evaluating the
    # block.
    private def self.with_absolute_path(path)
      original, @@current_path = @@current_path, path
      begin
        yield
      ensure
        @@current_path = original
      end
    end

    private def self.join_path(segment)
      if segment.starts_with?('/')
        "#{@@current_path}#{segment}"
      else
        "#{@@current_path}/#{segment}"
      end
    end

    # Scope a set of routes using `#controller` and `#path` in a single call.
    #
    # ```
    # scope path: "/posts", controller: PostsController do
    #  get "", :index     # GET /posts     => PostsController#index
    #  get ":id", :show   # GET /posts/:id => PostsController#show
    # end
    # ```
    macro scope(*, path = nil, controller = nil)
      {% if path %}
        path({{path}}) do
      {% end %}

      {% if controller %}
        controller({{controller}}) do
      {% end %}

      {{yield}}

      {% if controller %} end {% end %}
      {% if path %} end {% end %}
    end

    # Scope a set of routes under the same `path` and controllers inside the
    # same module namespace.
    #
    # ```
    # namespace :api do
    #   namespace :v1 do
    #     resources :posts # GET /api/v1/posts => Api::V1::PostsController#index
    #   end
    # end
    # ```
    macro namespace(name)
      path({{name.id.stringify}}) do
        with_namespace({{name.id.stringify.camelcase}}) do
          {{yield}}
        end
      end
      reset_namespace({{Frost::Routes::NAMESPACE_SCOPE.last}})
    end

    private macro with_namespace(klass)
      {%
        if namespace = Frost::Routes::NAMESPACE_SCOPE.last
          klass = "#{namespace.id}::#{klass.id}"
        end
      %}
      {% Frost::Routes::NAMESPACE_SCOPE << klass %}
      {{yield}}
    end

    private macro reset_namespace(klass)
      {% Frost::Routes::NAMESPACE_SCOPE << klass %}
    end

    # Declares all CRUD routes for a REST resource in a single call.
    #
    # ```
    # resources :posts
    # # GET    /posts          => PostsController#index
    # # GET    /posts/:id      => PostsController#show
    # # GET    /posts/new      => PostsController#new
    # # GET    /posts/:id/edit => PostsController#show
    # # POST   /posts          => PostsController#create
    # # PUT    /posts/:id      => PostsController#replace
    # # PATCH  /posts/:id      => PostsController#update
    # # DELETE /posts/:id      => PostsController#destroy
    # ```
    #
    # You may limit the generated routes with `only` and `except`:
    # ```
    # resources :comments, only: %i[index show create]
    # # GET  /posts     => PostsController#index
    # # GET  /posts/:id => PostsController#show
    # # POST /posts     => PostsController#create
    # ```
    #
    # You may nest resources:
    #
    # ```
    # resources :posts do
    #   resources :comments
    # end
    # # GET    /posts/:post_id/comments          => CommentsController#index
    # # GET    /posts/:post_id/comments/:id      => CommentsController#show
    # # GET    /posts/:post_id/comments/new      => CommentsController#new
    # # GET    /posts/:post_id/comments/:id/edit => CommentsController#show
    # # POST   /posts/:post_id/comments          => CommentsController#create
    # # PUT    /posts/:post_id/comments/:id      => CommentsController#replace
    # # PATCH  /posts/:post_id/comments/:id      => CommentsController#update
    # # DELETE /posts/:post_id/comments/:id      => CommentsController#destroy
    # ```
    macro resources(name, *,
      only = %i[index show new edit create update replace destroy],
      except = %i[],
      &block
    )
      {% name_s = name.id.stringify %}

      controller "{{name_s.camelcase.id}}Controller" do
        path {{name_s}} do
          {% if only.includes?(:index) && !except.includes?(:index) %}
            get "", action: "index"
          {% end %}

          {% if only.includes?(:show) && !except.includes?(:show) %}
            get ":id", action: "show"
          {% end %}

          {% if only.includes?(:new) && !except.includes?(:new) %}
            get "new", action: "new"
          {% end %}

          {% if only.includes?(:edit) && !except.includes?(:edit) %}
            get ":id/edit", action: "edit"
          {% end %}

          {% if only.includes?(:create) && !except.includes?(:create) %}
            post "", action: "create"
          {% end %}

          {% if only.includes?(:replace) && !except.includes?(:replace) %}
            put ":id", action: "replace"
          {% end %}

          {% if only.includes?(:update) && !except.includes?(:update) %}
            patch ":id", action: "update"
          {% end %}

          {% if only.includes?(:destroy) && !except.includes?(:destroy) %}
            delete ":id", action: "destroy"
          {% end %}
        end

        {% if block %}
          %member_path = "{{name.id}}/:#{Inflections.singularize({{name_s}})}_id"

          with_collection_path join_path({{name.id.stringify}}) do
            with_member_path join_path(%member_path) do
              path %member_path do
                {{yield}}
              end
            end
          end
        {% end %}
      end
    end

    private def self.with_collection_path(path)
      original, @@current_collection_path = @@current_collection_path, path
      begin
        yield
      ensure
        @@current_collection_path = original
      end
    end

    private def self.with_member_path(path)
      original, @@current_member_path = @@current_member_path, path
      begin
        yield
      ensure
        @@current_member_path = original
      end
    end

    # Declare additional routes on a resource's collection.
    #
    # ```
    # resources :posts do
    #   collection do
    #     get :published # GET /posts/published => PostsController#published
    #   end
    # end
    # ```
    def self.collection
      raise "ERROR: #collection must be called within a #resource block" unless @@current_collection_path
      with_absolute_path(@@current_collection_path) { yield }
    end

    # Declare additional routes to an identified resource.
    #
    # ```
    # resources :posts do
    #   member do
    #     post :publish # POST /posts/:id/publish => PostsController#publish
    #   end
    # end
    # ```
    def self.member
      raise "ERROR: #member must be called within a #resource block" unless @@current_member_path
      with_absolute_path(@@current_member_path) { yield }
    end

    {% for http_method in %w[options head get post put patch delete] %}
      # Shortcut for `match({{http_method}}, path, controller, action)`
      macro {{http_method.id}}(path, controller, action)
        match({{http_method}}, \{{path}}, \{{controller}}, \{{action}})
      end

      # Shortcut for `match({{http_method}}, path, action)`.
      macro {{http_method.id}}(path, action)
        match({{http_method}}, \{{path}}, \{{action}})
      end

      # Shortcut for `match({{http_method}}, action)`.
      macro {{http_method.id}}(action)
        match({{http_method}}, \{{action}})
      end
    {% end %}

    # The actual method to define a route.
    #
    # ```
    # match "GET", "/", RootController, :show
    # # GET / => RootController#show
    #
    # match "DELETE", "/posts/:id", PostsController, :destroy
    # # DELETE /posts/:id => PostsController#destroy
    # ```
    macro match(http_method, path, controller, action)
      {%
        if namespace = Frost::Routes::NAMESPACE_SCOPE.last
          controller = "#{namespace.id}::#{controller.id}"
        end
      %}
      Frost.handler.match({{http_method}}, join_path({{path}})) do |ctx, params|
        %controller = {{controller.id}}.new(ctx, params, {{action.id.stringify}})
        %controller.run_action do
          %controller.{{action.id}}()
        end
        {{controller.id}}.default_render(%controller, {{action.id.symbolize}})
      end
    end

    # Shortcut for `match(http_method, action, action)`, assuming that the path
    # and the action are identical.
    #
    # Assumes that the controller has been specified in outer scope, either
    # explicitly using `#controller` or `#scope` or implicitly with `#resources`.
    #
    # ```
    # controller PostsController do
    #   match "GET", :published # GET /published => PostsController#published
    # end
    # ```
    macro match(http_method, action)
      match {{http_method}}, {{action.id.stringify}}, {{action}}
    end

    # Shortcut for `match(http_method, path, controller, action)`.
    #
    # Assumes that the controller has been specified in outer scope, either
    # explicitly using `#controller` or `#scope` or implicitly with `#resources`.
    #
    # ```
    # controller PostsController do
    #   match "GET", "/posts", :index          # GET /posts     => PostsController#index
    #   match "DELETE", "/posts/:id", :destroy # GET /posts/:id => PostsController#destroy
    # end
    # ```
    macro match(http_method, path, action)
      {% if Frost::Routes::CONTROLLER_SCOPE.last %}
        match({{http_method}}, {{path}}, {{Frost::Routes::CONTROLLER_SCOPE.last}}, {{action}})
      {% else %}
        {% raise "ERROR: you must specify a controller" %}
      {% end %}
    end
  end
end
