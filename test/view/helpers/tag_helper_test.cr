require "../../test_helper"
require "../../../src/view/helpers"

class Frost::View::Helpers::TagHelperTest < Minitest::Test
  include Helpers

  def test_tag
    # returns a safe string
    assert_instance_of SafeString, tag(:hr)

    # self closing tag with attributes
    assert_equal %(<hr/>), tag(:hr)

    assert_equal %(<meta charset="utf-8"/>),
      tag(:meta, charset: "utf-8")

    assert_equal %(<img alt="" src="/assets/logo.png" class="logo is-big"/>),
      tag(:img, alt: "", src: "/assets/logo.png", class: "logo is-big")

    assert_equal %(<input required readonly maxlength="32"/>),
      tag(:input, required: true, readonly: true, maxlength: 32)

    # array attribute value
    assert_equal %(<input class="form-control required"/>),
      tag(:input, class: %w[form-control required])

    assert_equal %(<input data-class="form-control required"/>),
      tag(:input, data: { class: %w[form-control required] })

    # nested attributes
    assert_equal %(<input type="text" data-name="value"/>),
      tag(:input, type: "text", data: { name: "value" } )

    # escapes attributes
    assert_equal %(<img alt="&lt;a href=&quot;&quot;&gt;&lt;/a&gt;"/>),
      tag(:img, alt: %(<a href=""></a>))

    assert_equal %(<img &gt;&lt;a href="inject"/>),
      tag(:img, "><a href": "inject")

    assert_equal %(<img &gt;&lt;a-&gt;&lt;a href="inject"/>),
      tag(:img, "><a": { "><a href": "inject" })
  end

  def test_content_tag
    # it returns a safe string
    assert_instance_of SafeString, content_tag(:div)

    # generates tag with inner contents
    assert_equal %(<div></div>), content_tag(:div)

    assert_equal %(<div class="col is-large">some contents</div>),
      content_tag(:div, "some contents", class: "col is-large")

    assert_equal %(<div><img src="" alt=""/></div>),
      content_tag(:div, tag(:img, src: "", alt: ""))

    # escapes unsafe contents
    assert_equal %(<div>some &lt;a href=&quot;/malware&quot;&gt;unsafe&lt;/a&gt; content</div>),
      content_tag(:div, %(some <a href="/malware">unsafe</a> content))

    assert_equal %(<div>some <a href="/download">safe</a> content</div>),
      content_tag(:div, %(some <a href="/download">safe</a> content).html_safe)
  end

  def test_content_tag_with_block
    # it returns a safe string
    assert_instance_of SafeString, content_tag(:div) {}

    # generates tag with inner content
    assert_equal %(<div></div>), content_tag(:div) {}

    assert_equal %(<div class="col is-large">some contents</div>),
      content_tag(:div, class: "col is-large") { concat "some contents" }

    assert_equal %(<div><input name="key"/><input name="value"/></div>), content_tag(:div) {
      concat tag(:input, name: "key")
      concat tag(:input, name: "value")
    }

    # escapes unsafe contents
    assert_equal %(<div>some &lt;a href=&quot;/malware&quot;&gt;unsafe&lt;/a&gt; content</div>),
      content_tag(:div) { concat %(some <a href="/malware">unsafe</a> content) }

    assert_equal %(<div>some <a href="/download">safe</a> content</div>),
      content_tag(:div) { concat %(some <a href="/download">safe</a> content).html_safe }
  end

  private def __str__
    @__str__ ||= SafeBuffer.new(IO::Memory.new)
  end
end
