require "../../test_helper"

class Frost::View::UrlHelperTest < Minitest::Test
  include Frost::View::CaptureHelper
  include Frost::View::TagHelper
  include Frost::View::FormTagHelper
  include Frost::View::UrlHelper

  def test_link_to
    assert_equal %(<a href="/">somewhere</a>), link_to("somewhere", "/")
    assert_equal %(<a href="https://example.com/search?q=foo">external</a>), link_to("external", "https://example.com/search?q=foo")
    assert_equal %(<a href="/article/1">article</a>), link_to("/article/1") { "article" }
    assert_equal %(<a class="edit" href="/user/edit">profile</a>), link_to("profile", "/user/edit", { class: "edit" })
  end

  def test_button_to
    assert_equal %(<form action="/url" class="button_to" method="post">#{utf8_enforcer_tag}<button>btn</button></form>),
      button_to("btn", "/url")

    assert_equal %(<form action="/url" class="button_to" method="post">#{utf8_enforcer_tag}<button>contents</button></form>),
      button_to("/url") { "contents" }

    assert_equal %(<form action="/url" class="button_to" method="post">#{utf8_enforcer_tag}<button class="btn-success">btn</button></form>),
      button_to("btn", "/url", attributes: { class: "btn-success" })

    assert_equal %(<form action="/url" class="button_to" method="get">#{utf8_enforcer_tag}<button class="btn-success">btn</button></form>),
      button_to("btn", "/url", "get", { class: "btn-success" })

    assert_equal %(<form action="/" class="button_to" method="post"><input name="_method" type="hidden" value="delete"/>#{utf8_enforcer_tag}<button>remove</button></form>),
      button_to("remove", "/", method: "delete")
  end
end
