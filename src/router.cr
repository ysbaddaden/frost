require "./controller"
require "./router/radix_handler"

module Frost
  def self.handler : Router::RadixHandler
    @@handler ||= Router::RadixHandler.new
  end

  # Declare your application's routes.
  def self.draw_routes
    with Frost::Router yield Frost::Router
  end

  module Router
    # nodoc
    CONTROLLER_SCOPE = [] of Frost::Controller

    # Scope a set of routes to use a controller.
    macro controller(klass)
      # Crystal-macros-fu:
      #
      # We need two inner macros: the first will set the controller and evaluate
      # the block, the second will reset the scope. This is required for the
      # block to access the specified controller. If manipulated the scope
      # without inner macros, then crystal would push the controller, reset the
      # controller and only then evaluate the block (oops).
      with_controller({{klass}}) do
        {{yield}}
      end

      # If you understood the previous comment, you'll understand that `.last`
      # is resolved _before_ resolving `with_controller` hence returns the
      # *current* controller.
      reset_controller({{Frost::Router::CONTROLLER_SCOPE.last}})
    end

    # nodoc
    macro with_controller(klass)
      {% Frost::Router::CONTROLLER_SCOPE << klass %}
      {{yield}}
    end

    # nodoc
    macro reset_controller(klass)
      # There is no ArrayLiteral#pop, so we push the previous value *again*
      {% Frost::Router::CONTROLLER_SCOPE << klass %}
    end

    # nodoc
    @@current_path : String?

    ## Scope a set of routes under a parent path.
    def self.path(path : String)
      previous, @@current_path = @@current_path, join_path(path)
      yield
    ensure
      @@current_path = previous
    end

    # Scope a set of routes using `#controller` and `#path` in a single call.
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

    {% for http_method in %w[options head get post put patch delete] %}
      macro {{http_method.id}}(path, controller, action)
        match({{http_method}}, \{{path}}, \{{controller}}, \{{action}})
      end

      macro {{http_method.id}}(path, action)
        match({{http_method}}, \{{path}}, \{{action}})
      end
    {% end %}

    macro match(http_method, path, controller, action)
      Frost.handler.match({{http_method}}, join_path({{path}})) do |ctx, params|
        {{controller.id}}.new(ctx, params).{{action.id}}()
      end
    end

    macro match(http_method, path, action)
      {% if Frost::Router::CONTROLLER_SCOPE.last %}
        match({{http_method}}, {{path}}, {{Frost::Router::CONTROLLER_SCOPE.last}}, {{action}})
      {% else %}
        {% raise "ERROR: you must specify a controller" %}
      {% end %}
    end

    private def self.join_path(path)
      if path.starts_with?('/')
        "#{@@current_path}#{path}"
      else
        "#{@@current_path}/#{path}"
      end
    end
  end
end
