require "./context"

module Frost
  class Session::Handler
    include HTTP::Handler

    def initialize(
      store : Store,
      cookie_name : String = "sid",
      cookie_options : CookieOptions? = CookieOptions.new,
    )
      Session.store = store
      Session.cookie_name = "sid"
      Session.cookie_options = cookie_options
    end

    def call(context : HTTP::Server::Context) : Nil
      call_next(context)
    ensure
      context.write_session
    end
  end
end
