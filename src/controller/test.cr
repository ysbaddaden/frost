require "../support/core_ext/http/headers"
require "./assertions"
require "./session/test_store"

module Trail
  class Controller
    module Session
      def session_store
        TestStore
      end
    end

    class Test < Minitest::Test
      include Assertions

      getter! :response

      def dispatcher
        @dispatcher ||= ShardRegistry::Dispatcher.new
      end

      def session
        @session ||= {} of String => String
      end

      # :nodoc:
      def after_teardown
        Session::TestStore.reset
        @session = nil
        super
      end

      {% for method in %w(options head get delete) %}
        def {{ method.id }}(path, headers = nil, userinfo = nil)
          request = HTTP::Request.new({{ method.upcase }}, path, headers: HTTP::Headers.from(headers))
          request.headers["Host"] ||= "test.host"

          if @session
            Session::TestStore.new(request).set_data(session)
          end

          if userinfo
            request.headers["Authorization"] = "Basic #{Base64.encode(userinfo)}"
          end

          @response = dispatcher.call(request)
        end
      {% end %}

      {% for method in %w(post put patch) %}
        def {{ method.id }}(path, body : String, headers = nil, userinfo = nil)
          request = HTTP::Request.new({{ method.upcase }}, path, headers: HTTP::Headers.from(headers), body: body)
          request.headers["Host"] ||= "test.host"

          if @session
            Session::TestStore.new(request).set_data(session)
          end

          if userinfo
            request.headers["Authorization"] = "Basic #{Base64.encode(userinfo)}"
          end

          @response = dispatcher.call(request)
        end

        # TODO: encode Hash params as application/x-www-form-urlencoded
        #def {{ method.id }}(path, params : Hash, headers = nil, userinfo = nil)
        #  body = ""
        #
        #  headers ||= HTTP::Headers.from(headers)
        #  headers["Content-Type"] = "application/x-www-form-urlencoded"
        #
        #  {{ method.id }}(path, body, headers)
        #end
      {% end %}
    end
  end
end
