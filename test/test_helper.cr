require "minitest/autorun"
require "../src/frost"

# initialize the mimetype library to avoid lazy loading it on-demand (MT unsafe)
MIME.init(true)

module Frost
  def self.clear_routes
    @@handler = nil
  end

  {% Frost::View::SEARCH_PATHS << "#{__DIR__}/views" %}
end

module Frost::Controller::TestHelper
  macro call(action, params = {} of String => String, headers = nil, method = "GET")
    %context, %io = new_context({{method}}, "/", {{headers}})
    %params = ({{params}}).reduce(Frost::Routes::Params.new) { |a, (k, v)| a[k] = v; a }

    %controller = XController.new(%context, %params, {{action.id.stringify}})
    %controller.run_action do
      %controller.{{action.id}}()
    end
    XController.default_render(%controller, {{action.id.symbolize}})

    %context.response.close
    HTTP::Client::Response.from_io(%io.rewind)
  end

  def new_context(method, path, headers)
    request = HTTP::Request.new(method, path, headers)
    response = HTTP::Server::Response.new(io = IO::Memory.new)
    context = HTTP::Server::Context.new(request, response)
    {context, io}
  end
end
