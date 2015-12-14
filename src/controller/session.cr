require "http/params"
require "./session/cookie_store"

module Frost
  class Controller
    # User sessions.
    #
    # Sessions are automatically created, read and saved. You may disable them
    # for your whole application, or just some controllers or actions by
    # overloading the session_enabled` method.
    module Session
      # Overload to change the default session options.
      #
      # Available options:
      # - `cookie_name` — the session cookie name (defaults to `_session`).
      # - `expire_after` — how long in seconds before the session expires (defaults to 20 minutes).
      def session_options
        {
          cookie_name: "_session",
          expire_after: 20.minutes.to_i,
        }
      end

      # The `Store` class to use for storing sessions. Defaults to `CookieStore`.
      def session_store
        CookieStore
      end

      # The actual session object. See `Store`.
      def session
        @session ||= session_store.new(request, response, session_options)
      end

      # Overload to either enable or disable sessions automatically. Defaults to
      # true.
      def session_enabled?
        true
      end

      # :nodoc:
      def run_action
        if session_enabled?
          # OPTIMIZE: read the session object lazily (?)
          session.read
          super { yield }
          session.save
        else
          super { yield }
        end
      end

      #def self.cache
      #  Frost.cache
      #end

      # Serializes the session object using `HTTP::Params`. Overload to change
      # the method (not recommended).
      def self.serialize(data)
        HTTP::Params.build do |builder|
          data.each { |k, v| builder.add(k, v) }
        end
      end

      # Deserializes the session object using `HTTP::Params`. Overload to change
      # the method (not recommended).
      def self.unserialize(str)
        HTTP::Params.parse(str)
      end
    end
  end
end
