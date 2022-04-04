require "../../test_helper"
require "../../../src/view/helpers"

class Frost::View::Helpers::TagHelperTest < Minitest::Test
  include Helpers

  def test_link_to
    assert_instance_of SafeString, link_to "home", "/"

    assert_equal %(<a href="/">home</a>), link_to "home", "/"
    assert_equal %(<a href="/">&lt;unsafe&gt;</a>), link_to "<unsafe>", "/"

    assert_equal %(<a href="/posts"><div>Posts</div></a>),
      link_to content_tag(:div, "Posts"), "/posts"

    assert_equal %(<a rel="nofollow" class="external" href="http://example.org">outside</a>),
      link_to "outside", "http://example.org", rel: "nofollow", class: "external"
  end

  def test_link_to_with_block
    assert_instance_of SafeString, link_to "home", "/"

    assert_equal %(<a href="/">home</a>), link_to "/" { concat "home" }
    assert_equal %(<a href="/">&lt;unsafe&gt;</a>), link_to "/" { concat "<unsafe>" }

    assert_equal %(<a href="/posts"><div>Some</div><div>Posts</div></a>), link_to "/posts" {
      concat content_tag(:div, "Some")
      concat content_tag(:div, "Posts")
    }

    assert_equal %(<a rel="nofollow" class="external" href="http://example.org">outside</a>),
      link_to "outside", "http://example.org", rel: "nofollow", class: "external"
  end

  private def __str__
    @__str__ ||= SafeBuffer.new(IO::Memory.new)
  end
end
