require "../../support/core_ext/http/cookies"

module Trail
  class Controller
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

        protected def data
          @data ||= {} of String => String
        end
      end

      module Identifier
        def generate_session_id
          SecureRandom.urlsafe_base64(16)
        end

        def regenerate_session_id
          @session_id = generate_session_id
        end

        def session_id
          @session_id ||= if request.cookies[cookie_name]?
                            cookie.value
                          else
                            generate_session_id
                          end
        end
      end

      abstract class Store
        include HashObject
        include Identifier

        def initialize(@request, @response, @options)
        end

        abstract def read
        abstract def save

        def destroy
          @session_id = @data = nil
          response.cookies.delete(cookie_name)
          set_cookie(cookie_name, "", expires: Time.at(0))
        end

        protected getter :request, :response, :options

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
