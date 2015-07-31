require "./support/core_ext/http/response"
require "./controller/**"

module Trail
  class Controller
    include Filtering
    include Rendering

    # The received `HTTP::Request` object.
    getter :request

    # The `HTTP::Response` object to be returned.
    getter :response

    # Parsed request params (URI, query string and body) as a
    # `Controller::Params` object.
    getter :params

    # Returns the current action as a String.
    getter :action_name

    def initialize(@request, @params, @action_name)
      @response = HTTP::Response.new(200, "")
    end

    # Returns the controller name as an underscored String.
    def controller_name
      @controller_name ||= self.class.name.underscore
    end

    # Default URL options used by generated named routes.
    #
    # Overload to change the defaults.
    def default_url_options
      @default_url_options ||= { protocol: "http" }
    end

    def url_options
      url_options = default_url_options.dup

      if protocol = request.headers["X-Forwarded-Proto"]?
        url_options[:protocol] = protocol
      end

      if host = request.headers["Host"]?
        url_options[:host] = host
      end

      url_options
    end

    macro inherited
      generate_run_action_callbacks
      generate_view_class
    end
  end
end
