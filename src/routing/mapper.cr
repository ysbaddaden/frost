require "./route_set"
require "./resources"
require "./scope"
require "./url_builder"

module Trail
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
    # class Trail::Routing::Mapper
    #   get "/", "pages#landing"
    #   resources :posts
    # end
    #
    # # my_app.cr
    # module MyApp
    #   {{ run "config/routes.cr" }}
    # end
    # ```
    #
    # This will generate the MyApp::Dispatcher class and the MyApp::NamedRoutes
    # module with helpers to generate routes. The later is meant to be included
    # in your app's ApplicationController.
    #
    # ### Simple Routes
    #
    # ```
    # match "/posts", "posts#index"
    # # GET /posts  => PostsController#index
    # ```
    #
    # You may have path params, that will be available as `params["id"]` in
    # the controller:
    # ```
    # match "/posts/:id", "posts#show"
    # # GET /posts/:id  => PostsController#show
    # ```
    #
    # You may specify the HTTP method, and have many of them:
    # ```
    # match "/posts/:id", "posts#update", via: [:put, :patch]
    # # PUT /posts/:id  => PostsController#update
    # # PATCH /posts/:id  => PostsController#update
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

      def self.to_crystal_s(io : IO)
        aggregate = {} of String => Array(Route)

        routes.each do |route|
          if aggregate[route.method.upcase]?
            aggregate[route.method.upcase] << route
          else
            aggregate[route.method.upcase] = [route]
          end
        end

        io << "class Dispatcher < Trail::Dispatcher\n"
        io << "  def _dispatch(request, params)\n"
        io << "    case request.method.upcase\n"
        aggregate.each do |method, routes|
          io << "    when " << method.upcase.inspect << "\n"
          io << "      case request.uri.path\n"
          routes.each { |route| io << route.to_crystal_s }
          io << "      end\n"
        end
        io << "    end\n\n"

        io << "    if controller\n"
        io << "      controller.response\n"
        io << "    else\n"
        io << "      raise Trail::Routing::RoutingError.new(\"No route for \#{ request.method.upcase } \#{ request.uri.path.inspect }\")\n"
        io << "    end\n"
        io << "  end\n"
        io << "end\n\n"

        io << "module NamedRoutes\n"

        routes
          .select { |route| route.route_name }
          .uniq { |route| route.route_name }
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

        io << "end\n\n"
      end

      private def self.routes
        @@routes
      end
    end

    at_exit do
      Mapper.to_crystal_s(STDOUT)
    end
  end
end
