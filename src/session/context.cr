module Frost
  class Session
    module Context
      @session : Frost::Session?

      def session : Frost::Session
        @session || load_session || create_session
      end

      def session? : Frost::Session?
        @session || load_session
      end

      private def load_session : Session?
        if cookie = request.cookies[Session.cookie_name]?
          @session = Session.store.find_session(cookie.value)
        end
      end

      private def create_session : Session
        Session.new.tap do |session|
          @session = session
          set_session_cookie
        end
      end

      def write_session : Nil
        if session = @session
          if session.changed?
            Session.store.write_session(session)
          else
            Session.store.extend_session(session)
          end
        end
      end

      def reset_session : Nil
        if session = session?
          Session.store.delete_session(session)
          session.reset!
          set_session_cookie
        end
      end

      def delete_session : Nil
        if session = session?
          Session.store.delete_session(session)
          delete_session_cookie
          @session = nil
        end
      end

      private def set_session_cookie : Nil
        if options = Session.cookie_options
          response.cookies << HTTP::Cookie.new(Session.cookie_name, session.public_id, **options.to_kwargs)
        else
          response.cookies[Session.cookie_name] = session.public_id
        end
      end

      private def delete_session_cookie : Nil
        response.cookies << HTTP::Cookie.new(Session.cookie_name, "", expires: Time.unix(0))
      end
    end
  end
end

class HTTP::Server::Context
  include Frost::Session::Context
end
