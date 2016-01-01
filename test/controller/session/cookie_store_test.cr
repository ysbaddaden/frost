require "../../test_helper"

module Frost::Controller::Session
  class CookieStoreTest < Minitest::Test
    def test_save
      response, session = new_session
      session["key"] = "value"
      session.save

      assert cookie = response.cookies["_session"]
      assert_equal "_session", cookie.name
      assert_equal (Time.now + 20.minutes).to_i, cookie.expires.try(&.to_i)
      refute_empty cookie.value
    end

    def test_read
      response, session = new_session(new_cookie)
      session.read

      assert_equal "value", session["key"]
      assert_raises(KeyError) { session["unknown"] }
      refute session["unknown"]?
      assert_equal "value", session.delete("key")
      refute session["key"]?
    end

    def test_read_reset_session_on_invalid_message
      value = sign(encrypt("key=value", SecureRandom.hex(32)))
      response, session = new_session(new_cookie(value))
      session.read
      refute session["key"]?
    end

    def test_read_reset_session_on_invalid_signature
      value = sign(encrypt("key=value"), SecureRandom.hex(32))
      response, session = new_session(new_cookie(value))
      session.read
      refute session["key"]?
    end

    def test_destroy
      response, session = new_session(new_cookie)
      session.destroy

      cookie = response.cookies["_session"]
      assert_equal "_session", cookie.name
      assert_equal 0, cookie.expires.try(&.to_i)
      assert_empty cookie.value
    end

    private def new_cookie(value = nil)
      value ||= sign(encrypt("key=value"))
      HTTP::Cookie.new("_session", value, expires: Time.at((Time.now + 20.minutes).to_i))
    end

    private def new_session(cookie = nil)
      response = HTTP::Response.new(200)
      request = HTTP::Request.new("GET", "/")

      if cookie
        request.headers["Set-Cookie"] = cookie.to_set_cookie_header
      end

      session = CookieStore.new(request, response, {
        cookie_name: "_session",
        expire_after: 20.minutes,
      })

      {response, session}
    end

    private def encrypt(value, secret = Frost.config.secret_key)
      Support::MessageEncryptor.new(secret).encrypt(value)
    end

    private def sign(value, secret = Frost.config.secret_key)
      Support::MessageVerifier.new(secret).sign(value)
    end
  end
end
