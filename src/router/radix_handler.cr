require "http/server"
require "radix"

class Frost::Router::RadixHandler
  include HTTP::Handler

  alias Callback = HTTP::Server::Context, Hash(String, String) -> Nil
  alias Router = Radix::Tree(Callback)

  # TODO: configure block to call on NO SUCH ROUTE event
  def initialize(@fallthrough = false)
    @routers = {} of String => Router
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
    router = @routers[http_method.upcase] ||= Router.new
    router.add(path, block)
  end

  def call(context : HTTP::Server::Context)
    request = context.request
    router = @routers[request.method] ||= Router.new
    result = router.try(&.find(request.path))

    if result.found?
      result.payload.call(context, result.params)
      context.response.flush
    elsif @fallthrough
      call_next(context)
    else
      no_such_route(context)
    end
  end

  private def no_such_route(context)
    response = context.response
    response.status = :not_found
    response << "404 Not Found"
    response.flush
  end
end
