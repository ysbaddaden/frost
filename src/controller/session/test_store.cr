require "./store"

module Frost
  class Controller
    module Session
      # :nodoc:
      class TestStore < Store
        CACHE = {} of String => String

        def self.reset
          CACHE.clear
        end

        def self.new(request)
          new(request, HTTP::Response.new(200), { cookie_name: "_session" })
        end

        def set_data(data)
          request.cookies << HTTP::Cookie.new(cookie_name, session_id)
          CACHE[session_id] = Session.serialize(data || {} of String => String)
        end

        def read
          if data = CACHE[session_id]?
            @data = Session.unserialize(data)
          end
        end

        def save
          set_cookie(cookie_name, session_id)
          CACHE[session_id] = Session.serialize(@data || {} of String => String)
        end

        def destroy
          CACHE.delete(session_id)
          super
        end
      end
    end
  end
end
