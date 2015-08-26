require "./routing/errors"

module Trail
  abstract class Dispatcher
    # Dispatches a request, catching any exception.
    #
    # If the exception is a RoutingError then a 404 Not Found page is
    # rendered, otherwise a 500 Internal Server Error page is rendered. You
    # may customize the rendered pages by overloading the `#not_found` and
    # `#internal_server_error` methods.
    def call(request)
      dispatch(request)
    rescue ex : Trail::Routing::RoutingError
      not_found(ex)
    rescue ex
      internal_server_error(ex)
    end

    # :nodoc:
    def dispatch(request)
      params = Trail::Controller::Params.new
      params.parse(request)

      if request.method.upcase == "POST"
        if m = params.delete("_method")
          request.method = m.to_s.upcase
        end
      end

      _dispatch(request, params)
    end

    # Dispatches a request to the appropriate controller and action.
    #
    # This method is usually implemented by Mapper.
    abstract def _dispatch(request)

    # TODO: render a generic 404 page (production)
    def not_found(ex)
      response = HTTP::Response.new(404, "#{ ex.message }\n")
      response.headers["Content-Type"] = "text/plain"
      response
    end

    # TODO: render a generic 500 page (production)
    def internal_server_error(ex)
      response = HTTP::Response.new(500, "#{ ex.class.name }: #{ ex.message }\n#{ ex.backtrace.join("\n") }")
      response.headers["Content-Type"] = "text/plain"
      response
    end
  end
end
