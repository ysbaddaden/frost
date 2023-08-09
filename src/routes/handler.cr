require "http/server"
require "./route_set"

class Frost::Routes::Handler
  include HTTP::Handler

  def initialize(@fallthrough = false)
    @routes = {} of String => RouteSet(Callback)
  end

  def configure(&) : Nil
    with self yield self
  end

  def match(http_method : String, path : String, &block : Callback) : Nil
    (@routes[http_method.upcase] ||= RouteSet(Callback).new).add(path, block)
  end

  def call(context : HTTP::Server::Context) : Nil
    request = context.request

    if routes = @routes[request.method]?
      if route = routes.find(request.path)
        return call(context, route)
      end
    end

    if @fallthrough
      call_next(context)
    else
      no_such_route(context)
    end
  end

  private def call(context, route) : Nil
    route.payload.call(context, route.params)
    context.response.flush
  end

  private def no_such_route(context) : Nil
    response = context.response
    response.status = :not_found
    response << "404 Not Found"
    response.flush
  end
end
