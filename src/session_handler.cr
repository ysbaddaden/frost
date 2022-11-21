require "frost/session/memory_store"

class HTTP::Server::Context
  @session : Frost::Session?

  def session : Frost::Session
    @session ||= Frost::Session.new
  end

  def session? : Frost::Session?
    @session
  end
end

class Frost::SessionHandler
  include HTTP::Handler

  def initialize(@cookie_name : String = "sid")
  end

  def call(context : HTTP::Server::Context) : Nil
    load_session(context)
    call_next(context)
    write_session(context)
  end

  private def load_session(context) : Nil
    if session_id = context.request.cookies[@cookie_name]
      context.session = Frost.session_store.find_session(session_id)
    end
  end

  private def write_session(context) : Nil
    if session = context.session?
      Frost.session_store.write_session(session)

      unless context.request.cookies[@cookie_name]? == session.id
        context.request.cookies[@cookie_name] = session.id
      end
    else
      context.request.cookies.delete(@cookie_name)
    end
  end
end
