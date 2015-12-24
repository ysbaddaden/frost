require "../test_helper"
require "../../src/controller/assertions"

class Frost::Controller::AssertionsTest < Minitest::Test
  include Frost::Controller::Assertions

  def test_css_to_xpath_element
    assert_equal "//*", css_to_xpath("*")
    assert_equal "//div", css_to_xpath("div")
  end

  def test_css_to_xpath_operators
    assert_equal "//ul//li//a", css_to_xpath("ul li a")

    assert_equal "//ul/li", css_to_xpath("ul>li")
    assert_equal "//ul/li/a", css_to_xpath("ul > li>a")

    assert_equal "//div/following-sibling::*[1]/self::p", css_to_xpath("div+p")
    assert_equal "//div/following-sibling::*[1]/self::p/following-sibling::*[1]/self::pre", css_to_xpath("div + p+pre")

    #assert_equal "//div/following-sibling::*[count(p)]", css_to_xpath("div ~ p")
  end

  def test_css_to_xpath_id
    assert_equal "//div[ @id = \"myid\" ]", css_to_xpath("div#myid")
    assert_equal "//*[ @id = \"myid\" ]", css_to_xpath("#myid")
  end

  def test_css_to_xpath_class_name
    assert_equal "//div[ contains(concat(\" \", @class, \" \"), concat(\" \", \"class\", \" \")) ]", css_to_xpath("div.class")
    assert_equal "//div[ contains(concat(\" \", @class, \" \"), concat(\" \", \"class\", \" \")) ][ contains(concat(\" \", @class, \" \"), concat(\" \", \"name\", \" \")) ]", css_to_xpath("div.class.name")
    assert_equal "//*[ contains(concat(\" \", @class, \" \"), concat(\" \", \"class\", \" \")) ]", css_to_xpath(".class")
  end

  def test_css_to_xpath_attribute
    assert_equal "//a[ @href ]", css_to_xpath("a[href]")
    assert_equal "//*[ @href ]", css_to_xpath("[href]")
    assert_equal "//a[ @href = \"https://example.com\" ]", css_to_xpath("a[href='https://example.com']")
    assert_equal "//a[ @href = \"/some/path\" ]", css_to_xpath("a[href=\"/some/path\"]")

    assert_equal "//div[ contains(concat(\" \", @foo, \" \"), concat(\" \", \"warning\", \" \") ]", css_to_xpath("div[foo~='warning']")
    assert_equal "//*[ contains(concat(\" \", @foo, \" \"), concat(\" \", \"warning\", \" \") ]", css_to_xpath("[foo~='warning']")

    assert_equal "//div[ @lang = \"en\" or starts-with(@lang, concat(\"en\", \"-\")) ]", css_to_xpath("div[lang|='en']")
    assert_equal "//*[ @lang = \"en\" or starts-with(@lang, concat(\"en\", \"-\")) ]", css_to_xpath("[lang|='en']")

    assert_equal "//div[ @me != \"you\" ]", css_to_xpath("div[me!='you']")
    assert_equal "//div[ contains(@me, \"you\") ]", css_to_xpath("div[me*='you']")
    assert_equal "//div[ starts-with(@me, \"you\") ]", css_to_xpath("div[me^='you']")
    assert_equal "//div[ substring(@me, string-length(@me) - 2) = \"you\" ]", css_to_xpath("div[me$='you']")
  end

  def test_css_to_xpath_nth_first_and_last_child
    assert_equal "//div/descendant::*[1]", css_to_xpath("div:first-child")
    assert_equal "//*[ last() ]", css_to_xpath(":last-child")

    assert_equal "//*[ (position() mod 2) = 1 ]", css_to_xpath(":nth-child(odd)")
    assert_equal "//*[ (position() mod 2) = 0 ]", css_to_xpath(":nth-child(even)")
    assert_equal "//*[ (position() mod 1) = 1 ]", css_to_xpath(":nth-child(1)")
    assert_equal "//*[ (position() mod 99) = 1 ]", css_to_xpath(":nth-child(99)")
  end

  def test_css_to_xpath_with_complex_query
    assert_equal "//body//p/following-sibling::*[1]/self::*[ contains(concat(\" \", @class, \" \"), concat(\" \", \"nav\", \" \")) ]/a[ contains(concat(\" \", @class, \" \"), concat(\" \", \"active\", \" \")) ][ @target = \"_blank\" ][ contains(concat(\" \", @class, \" \"), concat(\" \", \"double\", \" \")) ]",
      css_to_xpath("body p + .nav > a.active[target='_blank'].double")
  end
end
