require "xml"
require "../css/selectors"

module Frost::Integration::Assertions
  def assert_response(status : HTTP::Status, message = nil, file = __FILE__, line = __LINE__) : Bool
    assert_equal status, response.status, message, file, line
  end

  def assert_redirected_to(resource : String, message = nil, file = __FILE__, line = __LINE__) : Bool
    assert_includes 300..399, response.status_code, -> {
      "Expected redirect but got #{response.status} (#{response.status_code})"
    }
    assert_equal resource, response.headers["location"]?, message, file, line
  end


  def assert_select(selector : String, *, count : Range, message = nil, file = __FILE__, line = __LINE__) : Bool
    assert_select(selector, minimum: count.begin, maximum: count.end, text: text, message: message, file: file, line: line)
  end

  def assert_select(selector : String, *, count : Range, text : String, message = nil, file = __FILE__, line = __LINE__) : Bool
    assert_select(selector, minimum: count.begin, maximum: count.end, text: text, message: message, file: file, line: line)
  end

  def assert_select(selector : String, *, count : Number, message = nil, file = __FILE__, line = __LINE__) : Bool
    xpath = CSS::Selectors.to_xpath(selector)
    actual = html_document.xpath_float("count(#{xpath})").to_i

    message ||= -> { "Expected exactly #{count} element(s) matching #{selector.inspect} but got #{actual}" }
    assert_equal(count, actual, message, file, line)
  end

  def assert_select(selector : String, *, count : Number, text : String, message = nil, file = __FILE__, line = __LINE__) : Bool
    xpath = CSS::Selectors.to_xpath(selector)
    xpath = "#{xpath}[contains(concat(text(), *[text()]), #{text.inspect})]" if text
    actual = html_document.xpath_float("count(#{xpath})").to_i

    message ||= -> {
      "Expected exactly #{count} element(s) matching #{selector.inspect} with text #{text.inspect} but got #{actual}"
    }
    assert_equal(count, actual, message, file, line)
  end

  def assert_select(selector : String, *, minimum : Number? = nil, maximum : Number? = nil, message = nil, file = __FILE__, line = __LINE__) : Bool
    xpath = CSS::Selectors.to_xpath(selector)
    actual = html_document.xpath_float("count(#{xpath})").to_i

    minimum ||= 1
    message ||= -> { "Expected at least #{minimum} element(s) matching #{selector.inspect} but got #{actual}" }
    assert(actual >= minimum, message, file, line)

    if maximum
      message ||= -> { "Expected at most #{maximum} element(s) matching #{selector.inspect} but got #{actual}" }
      assert(actual <= maximum, message, file, line)
    end

    true
  end

  def assert_select(selector : String, *, minimum : Number? = nil, maximum : Number? = nil, text : String, message = nil, file = __FILE__, line = __LINE__) : Bool
    xpath = CSS::Selectors.to_xpath(selector)
    xpath = "#{xpath}[contains(concat(text(), *[text()]), #{text.inspect})]" if text
    actual = html_document.xpath_float("count(#{xpath})").to_i

    minimum ||= 1
    message ||= -> {
      "Expected at least #{minimum} element(s) matching #{selector.inspect} with text #{text.inspect} but got #{actual}"
    }
    assert(actual >= minimum, message, file, line)

    if maximum
      message ||= -> {
        "Expected at most #{maximum} element(s) matching #{selector.inspect} with text #{text.inspect} but got #{actual}"
      }
      assert(actual <= maximum, message, file, line)
    end

    true
  end

  def refute_select(selector : String, message = nil, file = __FILE__, line = __LINE__) : Bool
    assert_select selector, count: 0, message: message, file: file, line: line
  end

  def html_document : XML::Node
    @html_document ||=
      if response.content_type.try(&.starts_with?("text/html"))
        XML.parse_html(response.body)
      else
        raise "ERROR: unknown response type #{response.content_type}"
      end
  end
end
