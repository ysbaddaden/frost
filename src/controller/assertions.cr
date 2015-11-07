module Trail
  class Controller
    module Assertions
      def assert_response(status_code, message = nil)
        assert_equal status_code, response.status_code, message
      end

      def assert_redirected_to(url, message = nil)
        assert_includes [301, 302, 303], response.status_code
        assert_equal url, response.headers["Location"], message
      end
    end
  end
end
