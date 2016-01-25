require "../support/core_ext/http/server/response"

module Frost
  abstract class Controller
    class Response
      forward_missing_to @original

      def initialize(@original : HTTP::Server::Response)
      end

      def body
        @body || ""
      end

      def body?
        @body
      end

      def body=(str)
        # NOTE: we don't stream the body (yet) in order for after_action in
        #       controllers to be capable to alter headers and the response body.
        #self << str
        @body = str
      end

      def write_body
        if (body = @body) && !@flushed_body
          self << body
          @flushed_body = true
        end
      end

      def flush
        write_body
        @original.flush
      end

      def reset
        @body = @wrote_body = nil
        @original.reset
      end

      def close
        flush
        @original.close
      end
    end
  end
end
