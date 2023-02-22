require "./routes/*"

module Frost
  def self.routes(&)
    with Routes yield Routes
  end

  module Routes
    alias Callback = Proc(HTTP::Server::Context, Params, Nil)

    @@handler = Routes::Handler.new

    @[AlwaysInline]
    def self.handler : Routes::Handler
      @@handler
    end

    @[AlwaysInline]
    def self.options(path : String, &block : Callback)
      @@handler.match("OPTIONS", path, &block)
    end

    @[AlwaysInline]
    def self.head(path : String, &block : Callback)
      @@handler.match("HEAD", path, &block)
    end

    @[AlwaysInline]
    def self.get(path : String, &block : Callback)
      @@handler.match("GET", path, &block)
    end

    @[AlwaysInline]
    def self.post(path : String, &block : Callback)
      @@handler.match("POST", path, &block)
    end

    @[AlwaysInline]
    def self.put(path : String, &block : Callback)
      @@handler.match("PUT", path, &block)
    end

    @[AlwaysInline]
    def self.patch(path : String, &block : Callback)
      @@handler.match("PATCH", path, &block)
    end

    @[AlwaysInline]
    def self.delete(path : String, &block : Callback)
      @@handler.match("DELETE", path, &block)
    end

    @[AlwaysInline]
    def self.match(path : String, via : String, &block : Callback)
      @@handler.match(via.upcase, path, &block)
    end

    @[AlwaysInline]
    def self.match(path : String, via : Enumerable(String), &block : Callback)
      via.each do |http_method|
        @@handler.match(http_method.upcase, path, &block)
      end
    end

    @[AlwaysInline]
    def self.root(&block : Callback)
      @@handler.match("GET", "/", &block)
    end

    macro to(controller, action)
      ->(context : HTTP::Server::Context, route_params : Frost::Routes::Params) {
        controller = {{controller.id}}.new(context, route_params, {{action.id.stringify}})
        controller.run_action { controller.{{action.id}}() }
        nil
      }
    end

    macro redirect_to(url, status = HTTP::Status::FOUND)
      ->(context : HTTP::Server::Context, route_params : Frost::Routes::Params) {
        response = context.response
        response.headers["location"] = {{url}}.to_s
        response.status = {{status}}
        nil
      }
    end
  end
end
