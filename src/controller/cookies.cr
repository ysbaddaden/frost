module Trail
  class Controller
    class Cookies
      def initialize(@request, @response)
      end

      def [](name)
        @request.cookies[name.to_s].value
      end

      def []?(name)
        if cookie = @request.cookies[name.to_s]?
          cookie.value
        end
      end

      def []=(name, value)
        @response.cookies << HTTP::Cookie.new(name.to_s, value)
      end
    end

    def cookies
      @cookies ||= Cookies.new(request, response)
    end
  end
end
