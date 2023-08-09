require "minitest/autorun"
require "../src/frost"
require "../src/session/memory_store"
require "syn/mutex"
require "timecop"

# initialize the mimetype library to avoid lazy loading it on-demand (MT unsafe)
MIME.init(true)

module Timecop
  MUTEX = Syn::Mutex.new(:reentrant)

  self.safe_mode = true

  def self.travel(time : Time, & : Time -> V) : V forall V
    MUTEX.synchronize do
      send_travel(:travel, time) { |t| yield t }
    end
  end
end

module Frost
  Session.store = Session::MemoryStore.new(schedule_clean_cron: nil)
  Session.cookie_options = CookieOptions.new

  class Routes::Handler
    def clear : Nil
      @routes.clear
    end
  end

  module Controller::TestHelper
    macro call(action, route_params = {} of String => String, headers = nil, method = "GET", cookies = nil)
      %context, %io = new_context({{method}}, "/", {{headers}}, {{cookies}})
      %route_params = ({{route_params}}).reduce(Frost::Routes::Params.new) { |a, (k, v)| a[k] = v; a }

      %controller = XController.new(%context, %route_params, {{action.id.stringify}})
      %controller.run_action do
        %controller.{{action.id}}()
      end

      %context.write_session

      %context.response.close
      HTTP::Client::Response.from_io(%io.rewind)
    end

    def new_context(method, path, headers, cookies = nil)
      request = HTTP::Request.new(method, path, headers)
      cookies.add_request_headers(request.headers) if cookies
      response = HTTP::Server::Response.new(io = IO::Memory.new)
      context = HTTP::Server::Context.new(request, response)
      {context, io}
    end
  end
end
