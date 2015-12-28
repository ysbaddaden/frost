require "../../test_helper"

class Frost::View::FormTagHelperTest < Minitest::Test
  include Frost::View::CaptureHelper
  include Frost::View::TagHelper
  include Frost::View::FormTagHelper

  def test_button_tag
    assert_equal %(<button>msg</button>), button_tag("msg")
    assert_equal %(<button>alt</button>), button_tag { "alt" }
    assert_equal %(<button class="test">msg</button>), button_tag("msg", { class: "test" })
    assert_equal %(<button class="test">alt</button>), button_tag({ class: "test" }) { "alt" }
  end

  {% for name in %w(color email hidden password search telephone phone url) %}
    {% type = name == "telephone" || name == "phone" ? "tel" : name %}

    def test_{{ name.id }}_field_tag
      assert_equal %(<input name="{{ name.id }}" type="{{ type.id }}"/>),
        {{ name.id }}_field_tag(:{{ name.id }})

      assert_equal %(<input id="myInput" name="key" type="{{ type.id }}"/>),
        {{ name.id }}_field_tag(:key, nil, { id: "myInput" })

      assert_equal %(<input disabled name="key" type="{{ type.id }}"/>),
        {{ name.id }}_field_tag(:key, nil, { disabled: true })

      assert_equal %(<input class="small input required" name="key" type="{{ type.id }}"/>),
        {{ name.id }}_field_tag(:key, nil, { class: ["small", "input", "required"] })

      assert_equal %(<input id="{{ name.id }}" name="user_{{ name.id }}" type="{{ type.id }}" value="value"/>),
        {{ name.id }}_field_tag(:user_{{ name.id }}, "value", { id: "{{ name.id }}" })
    end
  {% end %}

  {% for type in %w(month week number range) %}
    def test_{{ type.id }}_field_tag
      assert_equal %(<input name="date" type="{{ type.id }}"/>), {{ type.id }}_field_tag(:date)
      assert_equal %(<input max="12" min="1" name="date_fragment" step="3" type="{{ type.id }}" value="12"/>),
        {{ type.id }}_field_tag(:date_fragment, 12, { min: 1, max: 12, step: 3 })
    end
  {% end %}

  def test_check_box_tag
    assert_equal %(<input name="enabled" type="check_box" value="1"/>), check_box_tag(:enabled)
    assert_equal %(<input checked id="post_draft" name="draft" type="check_box" value="yes"/>),
      check_box_tag(:draft, "yes", { id: "post_draft", checked: true })
  end

  def test_date_field_tag
    assert_equal %(<input name="published_at" type="date"/>), date_field_tag(:published_at)
    assert_equal %(<input id="post_published_at" name="published_at" type="date" value="2015-08-01"/>),
      date_field_tag(:published_at, "2015-08-01", { id: "post_published_at" })
  end

  def test_datetime_field_tag
    assert_equal %(<input name="published_at" type="datetime"/>),
      datetime_field_tag(:published_at)

    assert_equal %(<input id="post_published_at" name="published_at" type="datetime" value="2000-01-01T00:00:00+05:00"/>),
      datetime_field_tag(:published_at, "2000-01-01T00:00:00+05:00", { id: "post_published_at" })

    Time.now.tap do |now|
      assert_equal %(<input name="published_at" type="datetime" value="#{ now.iso8601 }"/>),
        datetime_field_tag(:published_at, now)

      assert_equal %(<input name="published_at" type="datetime" value="#{ now.to_utc.iso8601 }"/>),
        datetime_field_tag(:published_at, now.to_i)
    end
  end

  def test_datetime_local_field_tag
    assert_equal %(<input name="published_at" type="datetime-local"/>),
      datetime_local_field_tag(:published_at)

    assert_equal %(<input id="post_published_at" name="published_at" type="datetime-local" value="2000-01-01T00:00:00"/>),
      datetime_local_field_tag(:published_at, "2000-01-01T00:00:00", { id: "post_published_at" })

    Time.now.tap do |now|
      assert_equal %(<input name="published_at" type="datetime-local" value="#{ now.iso8601 }"/>),
        datetime_local_field_tag(:published_at, now)

      assert_equal %(<input name="published_at" type="datetime-local" value="#{ now.to_utc.iso8601 }"/>),
        datetime_local_field_tag(:published_at, now.to_i)
    end
  end

  def test_file_field_tag
    assert_equal %(<input name="upload" type="file"/>), file_field_tag(:upload)
    assert_equal %(<input multiple name="file" type="file"/>),
      file_field_tag(:file, { multiple: true })
  end

  def test_form_tag
    assert_equal %(<form action="/posts" method="post">#{ utf8_enforcer_tag }</form>),
      form_tag("/posts") {}

    assert_equal %(<form action="/posts" method="get">#{ utf8_enforcer_tag }</form>),
      form_tag("/posts", method: "get") {}

    assert_equal %(<form action="/posts" method="post"></form>),
      form_tag("/posts", enforce_utf8: false) {}

    assert_equal %(<form action="/posts" method="post"><input name="_method" type="hidden" value="delete"/>#{ utf8_enforcer_tag }</form>),
      form_tag("/posts", method: "delete") {}

    assert_equal %(<form action="/posts" method="post"><input name="_method" type="hidden" value="delete"/></form>),
      form_tag("/posts", method: "delete", enforce_utf8: false) {}

    assert_equal %(<form action="/posts" method="post"><input name="commit" type="submit" value="Save changes"/></form>),
      form_tag("/posts", enforce_utf8: false) { submit_tag }

    assert_equal %(<form action="/posts" class="test" method="post">#{ utf8_enforcer_tag }</form>),
      form_tag("/posts", attributes: { class: "test" }) {}
  end

  def test_label_tag
    assert_equal %(<label for="title">Title</label>), label_tag("title")
    assert_equal %(<label for="post_title">Post Title</label>), label_tag("post_title")
    assert_equal %(<label for="post_title">Title:</label>), label_tag("post_title", "Title:")

    assert_equal %(<label class="optional" for="post_title">Title:</label>),
      label_tag("post_title", "Title:", { class: "optional" })

    assert_equal %(<label for="post_title"><i class="required"></i> Title</label>),
      label_tag("post_title") { "<i class=\"required\"></i> Title" }

    assert_equal %(<label class="required" for="post_title"><i></i> Title</label>),
      label_tag("post_title", { class: "required" }) { "<i></i> Title" }
  end

  def test_radio_button_tag
    assert_equal %(<input name="choice" type="radio" value="1"/>),
      radio_button_tag("choice", 1)

    assert_equal %(<input id="choice-off" name="choice" type="radio" value="off"/>),
      radio_button_tag("choice", "off", { id: "choice-off" })
  end

  def test_select_tag
    assert_equal %(<select name="category"><option>serious</option><option>frivolous</option></select>), select_tag(:category) do
      concat content_tag(:option, "serious")
      concat content_tag(:option, "frivolous")
    end

    assert_equal %(<select name="status"><option>frozen</option><option>melted</option></select>),
      select_tag :status, %(<option>frozen</option><option>melted</option>)
  end

  def test_submit_tag
    assert_equal %(<input name="commit" type="submit" value="Save changes"/>), submit_tag
    assert_equal %(<input name="commit" type="submit" value="Create"/>), submit_tag "Create"
    assert_equal %(<input name="publish" type="submit" value="Publish"/>), submit_tag "Publish", "publish"
    assert_equal %(<input disabled name="publish" type="submit" value="Publish"/>), submit_tag "Publish", "publish", { disabled: true }
    assert_equal %(<input class="btn btn-success" name="publish" type="submit" value="Publish"/>), submit_tag "Publish", "publish", { class: "btn btn-success" }
  end

  def test_text_area_tag
    assert_equal %(<textarea name="body"></textarea>), text_area_tag("body")

    assert_equal %(<textarea name="body">some long text</textarea>),
      text_area_tag("body", "some long text")

    assert_equal %(<textarea class="small" name="post[body]">a small text</textarea>),
      text_area_tag("post[body]", "a small text", { class: "small" })
  end

  def test_time_field_tag
    assert_equal %(<input name="ring_at" type="time"/>),
      time_field_tag(:ring_at)

    assert_equal %(<input id="post_ring_at" name="ring_at" type="time" value="10:34:51.23"/>),
      time_field_tag(:ring_at, "10:34:51.23", { id: "post_ring_at" })

    Time.now.tap do |now|
      assert_equal %(<input name="ring" type="time" value="#{ now.to_s("%T") }"/>),
        time_field_tag(:ring, now)

      assert_equal %(<input name="ring_utc" type="time" value="#{ now.to_utc.to_s("%T") }"/>),
        time_field_tag(:ring_utc, now.to_i)
    end
  end
end
