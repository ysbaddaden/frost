require "./support/core_ext/http/request"
require "./support/core_ext/http/response"
require "./controller/errors"
require "./controller/filtering"
require "./controller/params"
require "./controller/rendering"
require "./controller/session"

module Frost
  # Controllers are the logic of the Web Application.
  #
  # ### Routes
  #
  # The `Dispatcher` will match HTTP requests URIs to controller methods
  # (named actions). For example the `get "/", "pages#landing"` route mapping
  # will look for, and instanciate, a PagesController class then run it's
  # `landing` method:
  #
  # ```
  # class PagesController < ApplicationController
  #   def landing
  #   end
  # end
  # ```
  #
  # See `Routing::Mapper` for more information on routes.
  #
  # ### Actions
  #
  # Controllers may have as many actions as necessary. Actions are meant to load
  # data (eg: from the database) then to render a HTTP response (eg: render a
  # template, redirect, etc). The `Dispatcher` will then take over and reply to
  # the connected client.
  #
  # ### Params
  #
  # Matched params from the URI (eg: `/pages/:id`), the query string params (eg:
  # `a=b&c=d`) and the body params are automatically parsed and available as a
  # `Hash(String, ParamType)` object. For example:
  # ```
  # {
  #   "id" => "1",
  #   "a" => "b",
  #   "c" => "d"
  # }`
  # ```
  #
  # ### Templates
  #
  # The example above doesn't load any data, nor does it renders or redirects,
  # the controller thus automatically searches for an
  # `app/views/pages/landing.html.ecr` template and tries to render it within
  # the `app/views/layouts/application.html.ecr` layout template.
  #
  # See `Rendering` for more information.
  #
  # ### Filters
  #
  # Sometimes we want to execute the same set of operations around a many
  # actions. Filters are simple methods that will be invoked before and after an
  # action executes, so we may ensure that a user is authenticated or can access
  # the data that the action would return for instance.
  #
  # See `Filtering` for more information.
  #
  # ### Session
  #
  # See `Session` and `Session::Store` for more information.
  #
  abstract class Controller
    # TODO: CSRF protection

    include Filtering
    include Rendering
    include Session

    # The received `HTTP::Request` object.
    getter :request

    # The `HTTP::Response` object to be returned. Prefer the `Rendering` methods
    # and avoid manipulating the response object directly.
    getter :response

    # Parsed request params (from the URI, query string and body).
    getter :params

    # Returns the current action as a String.
    getter :action_name

    # :nodoc:
    def initialize(@request, @params, @action_name)
      @response = HTTP::Response.new(200, "")
    end

    # Returns the controller name as an underscored String.
    def controller_name
      @controller_name ||= self.class.name.gsub(/Controller\Z/, "").underscore
    end

    # Overload to change the default URL options.
    def default_url_options
      @default_url_options ||= { protocol: "http" }
    end

    # Extends `#default_url_options`, infering the HTTP protocol and the
    # Server Host name from `#request`.
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

    # Overload to rescue an exception raised during an action. The exception
    # will be raised again if the methods returns false. Does nothing by default.
    #
    # Example:
    #
    # ```
    # class ApplicationController < Frost::Controller
    #   def rescue_from(exception)
    #     case exception
    #     when Frost::Record::RecordNotFound
    #       head 404
    #     else
    #       false
    #     end
    #   end
    # end
    # ```
    def rescue_from(exception)
      false
    end

    def run_action
      super { yield }
    rescue exception
      raise exception if rescue_from(exception) == false
    end

    macro inherited
      #generate_run_action_callbacks
      generate_view_class
    end
  end
end
