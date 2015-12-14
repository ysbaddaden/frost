require "./route_set"
require "./resources"
require "./scope"
require "./url_builder"

module Frost
  # See `Routing::Mapper` for documentation.
  module Routing
    # HTTP Requests route generator.
    #
    # ### Usage
    #
    # Routing::Mapper generates Crystal code based on a simple DSL. It's thus
    # required to run with the `run` macro. For example:
    #
    # ```
    # # config/routes.cr
    # class Frost::Routing::Mapper
    #   get "/", "pages#landing"
    #   resources :posts
    # end
    #
    # # my_app.cr
    # module MyApp
    #   {{ run "config/routes.cr", "--codegen" }}
    # end
    # ```
    #
    # This will generate the MyApp::Dispatcher class and the MyApp::NamedRoutes
    # module with helpers to generate routes. The later is meant to be included
    # in your app's ApplicationController.
    #
    # ### Mapping Routes
    #
    # Mapper declares how an HTTP request must be handled. In its most basic
    # form, it checks the request pathname and the HTTP method:
    #
    # ```
    # match "/posts", "posts#index"
    # # GET /posts  => PostsController#index
    # ```
    #
    # An advanced form (TODO) will allow to match on whatever else: the domain,
    # the HTTP protocol (HTTP or HTTPS) or whatever HTTP header.
    #
    # #### Path Params
    #
    # Routes may have path params, which are declared with a leading `:`. The
    # following example will make the param available as `params["id"]` in
    # PostsController:
    # ```
    # match "/posts/:id", "posts#show"
    # # GET /posts/123  => { "id" => "123" }
    # ```
    #
    # Path params are sometimes optional:
    # ```
    # match "/posts/:id(.:format)", "posts#show"
    # # GET /posts/1  => { "id" => "1" }
    # # GET /posts/1.json  => { "id" => "1", "format" => "1" }
    # ```
    #
    # In this example, the `:format` param and the preceding dot (`.`) are both
    # optional, so both `/posts/1` and `/posts/1.json` would match, whereas
    # `/posts/1.` wouldn't. If the dot wasn't optional it would be required and
    # `/posts/1` wouldn't match anymore.
    #
    # Path params are expected to be constrained within slashes (`/`) or dots
    # (`.`) but sometimes we want to match these separators too, this can be
    # achieved with the `*path` declaration:
    # ```
    # match "/wiki/*name", "wiki#show"
    # # GET /wiki/path/to/page  => { "name" => "path/to/page" }
    # ```
    #
    # You can still have leading params:
    # ```
    # match "/wiki/*name(.:format)", "wiki#show"
    # # GET /wiki/path/to/page.html  => { "name" => "path/to/page", "format" => "html" }
    # ```
    #
    # #### HTTP methods
    #
    # You may specify the HTTP method the route must match. The route will only
    # match for this (or these) method(s), and will never match another one.
    # ```
    # match "/posts/:id", "posts#delete", via: :delete
    # # DELETE /posts/:id  => PostsController#delete
    #
    # match "/posts/:id", "posts#update", via: [:put, :patch]
    # # PUT /posts/:id  => PostsController#update
    # # PATCH /posts/:id  => PostsController#update
    # ```
    #
    # You are encouraged to use one of the helper methods (`#options`, `#head`,
    # `#get`, `#post`, `#put`, `#patch` or `#delete`) for increased readability
    # of your route definitions:
    # ```
    # get "/posts", "posts#index"
    # # GET /posts  => PostsController#show
    #
    # post "/posts", "posts#create"
    # # POST /posts  => PostsController#create
    # ```
    #
    # ### Named Routes
    #
    # You may specify a route name, to have named routes helper methods
    # generated under the NamedRoutes module, which you are expected to include
    # into your controllers (eg: your global ApplicationController).
    #
    # ```
    # match "/", "pages#root", as: "root"
    # root_path  # => "/"
    # root_url   # => "http://example.com/"
    # ```
    #
    # The helper methods will require any path params required to match the
    # route:
    # ```
    # match "/posts/:id", "posts#show", as: "post"
    # post_path(1)  # => "/posts/1"
    # post_url(1)   # => "http://example.com/posts/1"
    # ```
    #
    # If a param is an object and responds to `to_param` this will be invoked
    # instead of `to_s`:
    # ```
    # post = Post.find(1)
    # post_path(post) # => "/posts/1"
    # ```
    #
    # ### Resources
    #
    # In order to achieve a full REST API, Frost provides the `#resource` and
    # `#resources` helpers to generate many routes at once:
    #
    # ```
    # resources :posts
    # # GET    /posts(.:format)           => PostsController#index
    # # GET    /posts/:id(.:format)       => PostsController#show
    # # GET    /posts/new(.:format)       => PostsController#new
    # # GET    /posts/:id/edit(.:format)  => PostsController#edit
    # # POST   /posts(.:format)           => PostsController#create
    # # PUT    /posts/:id(.:format)       => PostsController#replace
    # # PATCH  /posts/:id(.:format)       => PostsController#update
    # # DELETE /posts/:id(.:format)       => PostsController#delete
    # ```
    #
    # See `Resources` for more information.
    #
    # ### Scopes
    #
    # To further cleanup your route definitions, you can group options or a set
    # of routes under a same name or path.
    #
    # See `Scope` for more information.
    #
    module Mapper
      # TODO: constraints (segments, request, custom)

      extend Scope
      extend Resources

      # :nodoc:
      METHOD_NAMES = %w(options head get post put patch delete)

      @@routes = RouteSet.new

      {% for method in METHOD_NAMES %}
        # Delegates to `match path, action, via: :{{ method.id }}`
        def self.{{ method.id }}(path, action = nil, as = nil)
          match path, action, {{ method }}, as
        end
      {% end %}

      # Maps a route.
      #
      # * `path` — the HTTP request pathname the route will match (eg: # `"/posts/:post_id/comments/:id(.:format)"`
      # * `action` — the controller and method to match (eg: `"posts#show"`)
      # * `via` — the route matches the given HTTP verb(s) (defaults to `:get`)
      # * `as` — generate named route helpers
      #
      def self.match(path, action = nil, via = :get, as = nil)
        if action.is_a?(Nil)
          if path.is_a?(Symbol)
            controller, action = current_scope[:controller], path.to_s
            path = "/#{ path }"
          else
            raise ArgumentError.new("invalid action #{ path.inspect }")
          end
        else
          controller, action = action.split('#', 2)
        end

        if current_scope[:path]?
          path = "#{ current_scope[:path] }#{ path }"
        end

        if current_scope[:name]?
          controller = "#{ current_scope[:name] }/#{ controller }"
        end

        routes.push path.to_s, controller.not_nil!, action, via, as
      end

      # :nodoc:
      def self.to_crystal_s(io : IO)
        aggregate = {} of String => Array(Route)

        routes.each do |route|
          if aggregate[route.method.upcase]?
            aggregate[route.method.upcase] << route
          else
            aggregate[route.method.upcase] = [route]
          end
        end

        io << "class Dispatcher < Frost::Dispatcher\n"
        io << "  def _dispatch(request, params)\n"

        if aggregate.any?
          io << "    case request.method.upcase\n"
          aggregate.each do |method, routes|
            io << "    when " << method.upcase.inspect << "\n"
            io << "      case request.path\n"
            routes.each { |route| route.to_crystal_s(io) }
            io << "      end\n"
          end
          io << "    end\n\n"

          io << "    if controller\n"
          io << "      controller.response\n"
          io << "    else\n"
          io << "      raise Frost::Routing::RoutingError.new(\"No route for \#{ request.method.upcase } \#{ request.path.inspect }\")\n"
          io << "    end\n"
        else
          io << "    raise Frost::Routing::RoutingError.new(\"No route for \#{ request.method.upcase } \#{ request.path.inspect }\")\n"
        end

        io << "  end\n"
        io << "end\n\n"

        io << "module NamedRoutes\n"

        # NOTE: .not_nil! is required in .uniq otherwise an empty routes array
        #       will result in the run macro segfaulting (while compiling from
        #       cli passes)
        if routes.any?
          routes
            .select { |route| route.route_name }
            .uniq { |route| route.route_name.not_nil! }
            .each do |route|
              name = route.route_name
              builder = UrlBuilder.new(route.path)

              io << "  def #{ name }_path(#{ builder.to_args })\n"
              builder.required_params.each do |name|
                io << "    if #{ name }.responds_to?(:to_param); #{ name } = #{ name }.to_param; end\n"
              end
              io << "    " << builder.to_path
              io << "  end\n\n"

              io << "  def #{ name }_url(#{ builder.to_args(url: true) })\n"
              builder.required_params.each do |name|
                io << "    if #{ name }.responds_to?(:to_param); #{ name } = #{ name }.to_param; end\n"
              end
              io << builder.to_url << "\n"
              io << "  end\n\n"
            end
        end

        io << "end\n\n"
      end

      def self.pretty_print(io : IO)
        lines = Array(Array(String)).new(routes.size)

        routes.each do |route|
          lines << [
            route.route_name.to_s,
            route.method.upcase,
            route.path,
            "#{ route.controller }##{ route.action }",
          ]
        end

        # FIXME: using map results in "expected block to return Array(String), not NoReturn"
        #lines = routes.map do |route|
        #  [
        #    route.route_name.to_s as String,
        #    route.method.upcase as String,
        #    route.path as String,
        #    "#{ route.controller }##{ route.action }" as String,
        #  ]
        #end

        sizes = lines.inject([0, 0, 0, 0]) do |acc, line|
          line.each_with_index do |arg, i|
            acc[i] = arg.size if arg.size > acc[i]
          end
          acc
        end

        lines.each do |args|
          args.each_with_index do |arg, i|
            io << "  " unless i == 0
            io << arg.ljust(sizes[i])
          end
          io.puts
        end
      end

      private def self.routes
        @@routes
      end
    end

    def self.draw
      with Mapper yield

      if ARGV.any? { |arg| arg == "--codegen" }
        Mapper.to_crystal_s(STDOUT)
      else
        Mapper.pretty_print(STDOUT)
      end
    end
  end
end
