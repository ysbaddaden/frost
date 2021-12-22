require "http/server"
require "./route_set"

class Frost::Routes::Handler
  include HTTP::Handler

  alias Callback = Proc(HTTP::Server::Context, Frost::Routes::Params, Nil)

  # TODO: configure block to call on NO SUCH ROUTE event
  def initialize(@fallthrough = false)
    @routes = {} of String => RouteSet(Callback)
  end

  def configure
    with self yield self
  end

  {% for http_method in %w[options head get post patch put delete] %}
    def {{http_method.id}}(path, &block : Callback)
      match({{http_method.upcase}}, path, &block)
    end
  {% end %}

  def match(http_method, path, &block : Callback)
    (@routes[http_method.upcase] ||= RouteSet(Callback).new).add(path, block)
  end

  def call(context : HTTP::Server::Context)
    request = context.request

    if routes = @routes[request.method]?
      routes.each(request.path) do |match|
        # TODO: next unless matches constraints
        return call(context, match)
      end
    end

    if @fallthrough
      call_next(context)
    else
      no_such_route(context)
    end
  end

  private def call(context, result)
    result.payload.call(context, result.params)
    context.response.flush
  end

  private def no_such_route(context)
    response = context.response
    response.status = :not_found
    response << "404 Not Found"
    response.flush
  end
end
