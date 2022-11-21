require "../session"
require "../session/store"

module Frost
  @@session_store : Session::Store?
  @@session_store_mutex = Mutex.new(:unchecked)

  def self.session_store : Session::Store
    if session_store = @@session_store
      return session_store
    end

    if @@session_store_mutex.try_lock
      begin
        return @@session_store = {{yield}}
      ensure
        @@session_store_mutex.unlock
      end
    end

    until session_store = @@session_store
      sleep(0)
    end
    session_store
  end

  def self.session_store=(session_store : Session::Store)
    @@session_store_mutex.synchronize do
      @@session_store = session_store
    end
  end

  class Controller
    module Session
      def session : Frost::Session
        @context.session
      end

      def session? : Frost::Session?
        @context.session?
      end

      def reset_session : Nil
        if session = @context.session?
          Frost.session_store.delete_session(session)
          @context.session.reset!
        end
      end
    end
  end
end
