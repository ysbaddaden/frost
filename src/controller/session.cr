require "../session"
require "../session/store"

module Frost
  @@session_store : Session::Store?

  def self.session_store : Session::Store
    @@session_store || raise "ERROR: you must set Frost.session_store before using sessions"
  end

  def self.session_store=(session_store : Session::Store)
    @@session_store = session_store
  end

  class Controller
    module Session
      @session : Frost::Session?

      def session : Frost::Session
        @session || load_session || create_session
      end

      def session? : Frost::Session?
        @session || load_session
      end

      def load_session : Session?
        if cookie = request.cookies[session_cookie_name]?
          @session = Frost.session_store.find_session(cookie.value)
        end
      end

      def create_session : Session
        @session = Session.new
        set_session_cookie
        @session
      end

      def reset_session : Nil
        if session = session?
          Frost.session_store.delete_session(session)
          session.reset!
          set_session_cookie
        end
      end

      def delete_session : Nil
        if session = session?
          Frost.session_store.delete_session(session)
          response.cookies << Cookie.new(session_cookie_name, "", expires: Time.unix(0))
          @session = nil
        end
      end

      def set_session_cookie : Nil
        if options = session_cookie_options
          response.cookies << Cookie.new(session_cookie_name, session.public_id, **options)
        else
          response.cookies[session_cookie_name] = session.public_id
        end
      end

      def session_cookie_name : String
        "sid"
      end

      def session_cookie_options : NamedTuple?
      end

      def after_action
        if (session = @session) && session.changed?
          Frost.session_store.write_session(session)
        end
        super
      end
    end
  end
end
