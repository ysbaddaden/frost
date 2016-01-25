require "./routing/errors"

module Frost
  # Dispatcher connects the mapped routed (see `Routing`) and controller
  # actions (see `Controller`). This is an abstract class and the actual class
  # will be implemented by `Routing::Mapper`.
  abstract class Dispatcher
    # Dispatches a request, catching any exception.
    #
    # If the exception is a RoutingError then a 404 Not Found page is
    # rendered, otherwise a 500 Internal Server Error page is rendered. You
    # may customize the rendered pages by overloading the `#not_found` and
    # `#internal_server_error` methods.
    def call(context)
      begin
        dispatch(context)
      rescue ex : Frost::Routing::RoutingError
        not_found(context, ex)
      rescue ex
        Frost.logger.error { "#{ ex.class.name }: #{ ex.message }" }
        internal_server_error(context, ex)
      end

      context.response.flush

      nil
    ensure
      Record.release_connection
    end

    # :nodoc:
    def dispatch(context)
      request = context.request
      params = Frost::Controller::Params.parse(request.query)

      if request.headers["Content-Type"]? == "application/x-www-form-urlencoded"
        Frost::Controller::Params.parse(request.body, params)
      end

      if request.method.upcase == "POST"
        if m = params.delete("_method")
          request.method = m.to_s.upcase
        end
      end

      _dispatch(context, params)
    end

    # Dispatches a request to the appropriate controller and action.
    #
    # This method is usually implemented by Mapper.
    abstract def _dispatch(context, params)

    # TODO: render a generic 404 page (production)
    def not_found(context, ex)
      response = context.response
      response.status_code = 404
      response.content_type = "text/plain"
      response << "#{ ex.message }\n"
    end

    # TODO: render a generic 500 page (production)
    def internal_server_error(context, ex)
      response = context.response
      response.status_code = 500
      response.content_type = "text/plain"
      response << "#{ ex.class.name }: #{ ex.message }\n#{ ex.backtrace.join("\n") }"
    end
  end
end
