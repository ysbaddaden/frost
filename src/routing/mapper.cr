require "./route_set"
require "./resources"
require "./scope"
require "./url_builder"

module Trail
  module Routing
    # TODO: constraints (segments, request, custom)
    module Mapper
      extend Scope
      extend Resources

      # :nodoc:
      METHOD_NAMES = %w(options head get post put patch delete)

      @@routes = RouteSet.new

      {% for method in METHOD_NAMES %}
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

      def self.to_crystal_s
        aggregate = {} of String => Array(Route)

        routes.each do |route|
          if aggregate[route.method.upcase]?
            aggregate[route.method.upcase] << route
          else
            aggregate[route.method.upcase] = [route]
          end
        end

        String.build do |str|
          str << "class Dispatcher < Trail::Dispatcher\n"
          str << "  def _dispatch(request, params)\n"
          str << "    case request.method.upcase\n"
          aggregate.each do |method, routes|
            str << "    when " << method.upcase.inspect << "\n"
            str << "      case request.uri.path\n"
            routes.each { |route| str << route.to_crystal_s }
            str << "      end\n"
          end
          str << "    end\n\n"

          str << "    if controller\n"
          str << "      controller.response\n"
          str << "    else\n"
          str << "      raise Trail::Routing::RoutingError.new(\"No route for \#{ request.method.upcase } \#{ request.uri.path.inspect }\")\n"
          str << "    end\n"
          str << "  end\n"
          str << "end\n\n"

          str << "module NamedRoutes\n"

          routes
            .select { |route| route.route_name }
            .uniq { |route| route.route_name }
            .each do |route|
              name = route.route_name
              builder = UrlBuilder.new(route.path)

              str << "  def #{ name }_path(#{ builder.to_args })\n"
              builder.required_params.each do |name|
                str << "    if #{ name }.responds_to?(:to_param); #{ name } = #{ name }.to_param; end\n"
              end
              str << "    " << builder.to_path
              str << "  end\n\n"

              str << "  def #{ name }_url(#{ builder.to_args(url: true) })\n"
              builder.required_params.each do |name|
                str << "    if #{ name }.responds_to?(:to_param); #{ name } = #{ name }.to_param; end\n"
              end
              str << builder.to_url << "\n"
              str << "  end\n\n"
            end

          str << "end\n\n"
        end
      end

      private def self.routes
        @@routes
      end
    end

    at_exit do
      puts Mapper.to_crystal_s
    end
  end
end
