require "../test_helper"
require "../../src/integration/cookie_jar"

class Frost::Integration::CookieJarTest < Minitest::Test
  def test_add
    jar = CookieJar.new

    jar.add(HTTP::Cookies{"name" => "created"})
    assert_equal "created", jar.@cookies["name"].value, "Expected the cookie to jave been stored"

    jar.add(HTTP::Cookies{"name" => "updated"})
    assert_equal "updated", jar.@cookies["name"].value, "Expected the cookie to have been updated"

    jar.add(HTTP::Cookie.new("name", "delete_me", expires: Time.unix(0)))
    assert_nil jar.@cookies["name"]?, "Expected expired cookie to have been deleted"
  end

  def test_fill
    jar = CookieJar.new(HTTP::Cookies{"a" => "1", "b" => "2"})

    # sets session cookies
    request = HTTP::Request.new("GET", "/")
    jar.fill(request)
    assert request.headers.has_key?("Cookie")
    assert_equal "1", request.cookies["a"].value
    assert_equal "2", request.cookies["b"].value

    # add a cookie that expires in the future
    jar.add(HTTP::Cookies{"c" => HTTP::Cookie.new("c", "expiring", expires: 1.minute.from_now)})

    request = HTTP::Request.new("GET", "/")
    jar.fill(request)
    assert_equal "1", request.cookies["a"].value
    assert_equal "2", request.cookies["b"].value
    assert_equal "expiring", request.cookies["c"].value, "Expected non expired cookies to have been set"

    # back to the future
    Timecop.travel(5.minutes.from_now) do
      request = HTTP::Request.new("GET", "/")
      jar.fill(request)
      assert_equal "1", request.cookies["a"].value
      assert_equal "2", request.cookies["b"].value
      assert_nil request.cookies["c"]?, "Expected expired cookie to not have been set"
    end
  end

  def test_enumerable
    jar = CookieJar.new(HTTP::Cookies{"a" => "1", "b" => "2"})
    cookies = jar
      .map { |cookie| {cookie.name, cookie.value} }
      .sort_by! { |(name, _)| name }
    assert_equal [{"a", "1"}, {"b", "2"}], cookies
  end

  def test_clear
    jar = CookieJar.new(HTTP::Cookies{"name" => "created"})
    refute_empty jar

    jar.clear
    assert_empty jar
  end
end
