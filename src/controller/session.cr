require "../session"

module Frost
  class Controller
    module Session
      def session : Frost::Session
        @context.session
      end

      def session? : Frost::Session?
        @context.session?
      end

      def reset_session : Nil
        @context.reset_session
      end

      def delete_session : Nil
        @context.delete_session
      end
    end
  end
end
