require "http/server/handler"

class Frost::CORSHandler
  include HTTP::Handler

  DEFAULT_METHODS = %w[HEAD GET POST PUT PATCH DELETE]
  DEFAULT_HEADERS = %w[*]

  @origins : Array(String)
  @methods : Array(String)
  @headers : Array(String)
  @max_age : String

  def initialize(
    origins : String | Array(String),
    methods : String | Array(String) = DEFAULT_METHODS,
    headers : String | Array(String) = DEFAULT_HEADERS,
    max_age : Time::Span = 1.day,
  )
    @origins = origins.is_a?(Array) ? origins : [origins]
    @methods = methods.is_a?(Array) ? methods : [methods]
    @headers = headers.is_a?(Array) ? headers : [headers]
    @max_age = max_age.to_i.to_s
  end

  {% for setting in %w[origins headers methods] %}
    def {{setting.id}}=(value : String)
      @{{setting.id}} = [value]
    end

    def {{setting.id}}=(value : Array(String))
      @{{setting.id}} = value
    end
  {% end %}

  def call(context : HTTP::Server::Context) : Nil
    request, response = context.request, context.response

    if origin = request.headers["origin"]?
      method = request.headers["access-control-request-method"]?

      if allowed?(origin, method)
        headers = response.headers
        headers["access-control-allow-origin"] = origin
        headers["access-control-allow-methods"] = @methods.join(", ")
        headers["access-control-allow-headers"] = @headers.join(", ")
        headers["access-control-max-age"] = @max_age
      else
        response.status = :unauthorized
      end

      return if request.method == "OPTIONS"
    end

    call_next(context)
  end

  private def allowed?(origin, method)
    allowed_origin?(origin) && (!method || allowed_method?(method))
  end

  private def allowed_origin?(origin : String) : Bool
    @origins.includes?(origin) || @origins.includes?("*")
  end

  private def allowed_method?(method : String) : Bool
    @methods.includes?(method) || @methods.includes?("*")
  end
end
