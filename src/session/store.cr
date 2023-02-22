require "./cookie_options"

module Frost
  class Session
    class_property cookie_name : String = "sid"
    class_property cookie_options : CookieOptions? = nil

    @@store : Session::Store?

    def self.store : Session::Store
      @@store || raise "ERROR: you must set Frost::Session.store before using sessions"
    end

    def self.store=(store : Session::Store)
      @@store = store
    end

    abstract class Store
      # Searches a session by it's identifier. Returns `nil` if the session doesn't
      # exist or has expired. Returns a `Frost::Session` otherwise.
      abstract def find_session(session_id : String) : Session?

      # Writes the session. The session must now be findable by it's identifier.
      abstract def write_session(session : Session) : Nil

      # Deletes the session. The session must no longer be findable by it's
      # identifier.
      abstract def delete_session(session : Session) : Nil
    end
  end
end
