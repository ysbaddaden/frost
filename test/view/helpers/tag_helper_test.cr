require "../../test_helper"
require "../../../src/view/ecr"

class Trail::View::TagHelperTest < Minitest::Test
  include Trail::View::CaptureHelper
  include Trail::View::TagHelper

  def test_tag
    assert_equal "<br/>", tag(:br)
    assert_equal %(<hr class="pretty-line" id="mark"/>), tag(:hr, { class: "pretty-line", id: "mark" })
    assert_equal %(<hr class="pretty tuple line"/>), tag(:hr, { class: {"pretty", "tuple", "line"} })
    assert_equal %(<hr class="pretty array"/>), tag(:hr, { class: ["pretty", "array"] })
    assert_equal %(<input disabled type="text"/>), tag(:input, { type: "text", disabled: true })
    assert_equal %(<input type="text"/>), tag(:input, { type: "text", disabled: false })
    assert_equal %(<input type="submit" value="保存"/>), tag(:input, { type: "submit", value: "保存" })
    assert_equal %(<input type="submit" value="&lt;span&gt;"/>), tag(:input, { type: "submit", value: "<span>" })
    assert_equal %(<hr ng-if="test"/>), tag(:hr, { ng_if: "test" })
  end

  def test_content_tag
    assert_equal "<div></div>", content_tag(:div)
    assert_equal "<div>contents</div>", content_tag(:div, "contents")
    assert_equal "<div>alternate</div>", content_tag(:div) { "alternate" }
    assert_equal %(<p class="pretty" id="mark"></p>), content_tag(:p, nil, { class: "pretty", id: "mark" })
    assert_equal %(<div class="point">alternate</div>), content_tag(:div, { class: "point" }) { "alternate" }
    assert_equal %(<button disabled>Save</button>), content_tag(:button, "Save", { disabled: true })
    assert_equal %(<button>Create</button>), content_tag(:button, "Create", { disabled: false })
    assert_equal %(<form ng-if="test"></form>), content_tag(:form, nil, { ng_if: "test" })
  end

  def test_content_tag_in_ecr_template
    output = String.build do |__str__|
      output_buffers << __str__
      {{ run "../../../src/view/ecr/process", "#{ __DIR__ }/../../views/capture.ecr", "__buf__" }}
    end

    assert_match "<h1>inlined content</h1>", output
    assert_match "<p>\n  inner content\n</p>", output
    assert_match "<div>\n  <br/>\n</div>", output
    assert_match "<outer>\n  <inner>\n    <nested>\n      contents\n    </nested>\n  </inner>\n</outer>", output
  end
end
