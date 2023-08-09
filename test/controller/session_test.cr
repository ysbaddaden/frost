require "../test_helper"

class Frost::Controller::SessionTest < Minitest::Test
  include Frost::Controller::TestHelper

  class XController < Controller
    # creates or reuses a session to store a value
    def first
      session["key"] = params.route["value"]
    end

    # renders the value stored in session
    def second
      render plain: session["key"]?.to_s
    end

    # creates a new session
    def reset
      reset_session
    end

    # deletes the session
    def delete
      delete_session
    end
  end

  def test_session_cookie
    # creates a session
    response = call(:first, { "value" => "a value stored in session" })
    refute_nil response.cookies["sid"]?

    # validate the session cookie
    session_cookie = response.cookies["sid"]
    assert_equal "/", session_cookie.path
    assert session_cookie.samesite.try(&.lax?)
    assert_nil session_cookie.max_age, "expected a session cookie"
    assert_nil session_cookie.expires, "expected a session cookie"

    # the session is valid
    response = call(:second, cookies: response.cookies)
    assert_equal "a value stored in session", response.body
  end

  def test_reset_session
    # creates a session
    response = call(:first, { "value" => "value" })
    old_cookies = response.cookies

    # replaces the current session
    response = call(:reset, cookies: old_cookies)
    refute_nil response.cookies["sid"]?
    refute_equal old_cookies["sid"].value, response.cookies["sid"].value
    new_cookies = response.cookies

    # the old session has been deleted
    response = call(:second, cookies: old_cookies)
    assert_empty response.body

    # the new session has been cleared
    response = call(:second, cookies: new_cookies)
    assert_empty response.body
  end

  def test_delete_session
    # creates a session
    response = call(:first, { "value" => "value" })
    cookies = response.cookies

    # deletes the session (sets a cookie in the past)
    response = call(:delete_session, cookies: cookies)
    refute_nil response.cookies["sid"]?
    refute_nil response.cookies["sid"].expires
    assert response.cookies["sid"].expired?
    assert_empty response.cookies["sid"].value

    # the session has been deleted
    response = call(:second, cookies: cookies)
    assert_empty response.body
  end
end
