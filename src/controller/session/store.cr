require "../../support/core_ext/http/cookies"

module Frost
  abstract class Controller
    module Session
      module HashObject
        def [](key)
          data[key]
        end

        def []?(key)
          data[key]?
        end

        def []=(key, value)
          data[key] = value.to_s
        end

        def delete(key)
          data.delete(key)
        end

        protected def data
          @data ||= HTTP::Params.new({} of String => Array(String))
        end
      end

      module Identifier
        def generate_session_id
          SecureRandom.urlsafe_base64(16)
        end

        @session_id : String?

        def regenerate_session_id
          @session_id = generate_session_id
        end

        def session_id
          @session_id ||= if cookie = request.cookies[cookie_name]?
                            cookie.value
                          else
                            generate_session_id
                          end
        end
      end

      abstract class Store
        include HashObject
        include Identifier

        protected getter request : HTTP::Request
        protected getter response : HTTP::Server::Response
        protected getter options : Hash(Symbol, String | Time::Span)

        def initialize(@request, @response, @options)
        end

        abstract def read
        abstract def save

        def destroy
          @session_id = @data = nil
          response.cookies.delete(cookie_name)
          set_cookie(cookie_name, "", expires: Time.at(0))
        end

        def inspect(io)
          @data.inspect(io)
        end

        protected def set_cookie(name, value, expires = nil)
          expires ||= Time.at(Time.utc_now.to_i + options[:expire_after].to_i)
          response.cookies << HTTP::Cookie.new(name, value, expires: expires, domain: cookie_domain)
        end

        protected def cookie_domain
          options[:domain]? as String?
        end

        protected def cookie_name
          options[:cookie_name] as String
        end
      end
    end
  end
end
