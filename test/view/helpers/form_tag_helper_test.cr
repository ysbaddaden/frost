require "../../test_helper"

class Trail::View::FormTagHelperTest < Minitest::Test
  include Trail::View::CaptureHelper
  include Trail::View::TagHelper
  include Trail::View::FormTagHelper

  def test_button_tag
    assert_equal %(<button>msg</button>), button_tag("msg")
    assert_equal %(<button>alt</button>), button_tag { "alt" }
    assert_equal %(<button class="test">msg</button>), button_tag("msg", { class: "test" })
    assert_equal %(<button class="test">alt</button>), button_tag({ class: "test" }) { "alt" }
  end

  def test_check_box_tag
    assert_equal %(<input name="enabled" type="check_box" value="1"/>), check_box_tag(:enabled)
    assert_equal %(<input id="post_draft" name="draft" type="check_box" value="yes"/>),
      check_box_tag(:draft, "yes", { id: "post_draft" })
  end

  def test_color_field_tag
    assert_equal %(<input name="colour" type="color"/>), color_field_tag(:colour)
    assert_equal %(<input id="bg_color" name="colour" type="color" value="#fff"/>),
      color_field_tag(:colour, "#fff", { id: "bg_color" })
  end

  def test_date_field_tag
    assert_equal %(<input name="published_at" type="date"/>), date_field_tag(:published_at)
    assert_equal %(<input id="post_published_at" name="published_at" type="date" value="2015-08-01"/>),
      date_field_tag(:published_at, "2015-08-01", { id: "post_published_at" })
  end

  # TODO: test min, max, step attributes
  # TODO: test with Date, Time and timestamps attribute values
  def test_datetime_field_tag
    assert_equal %(<input name="published_at" type="datetime"/>), datetime_field_tag(:published_at)
    assert_equal %(<input id="post_published_at" name="published_at" type="datetime" value="2000-01-01T00:00:00+05:00"/>),
      datetime_field_tag(:published_at, "2000-01-01T00:00:00+05:00", { id: "post_published_at" })
  end

  # TODO: test min, max, step attributes
  # TODO: test with Date, Time and timestamps attribute values
  def test_datetime_local_field_tag
    assert_equal %(<input name="published_at" type="datetime-local"/>), datetime_local_field_tag(:published_at)
    assert_equal %(<input id="post_published_at" name="published_at" type="datetime-local" value="2000-01-01T00:00:00"/>),
      datetime_local_field_tag(:published_at, "2000-01-01T00:00:00", { id: "post_published_at" })
  end

  def test_email_field_tag
    skip "todo"
  end

  def test_file_field_tag
    skip "todo"
  end

  def test_form_tag
    skip "todo"
  end

  def test_hidden_field_tag
    skip "todo"
  end

  def test_label_tag
    skip "todo"
  end

  def test_month_field_tag
    skip "todo"
  end

  def test_number_field_tag
    skip "todo"
  end

  def test_password_field_tag
    skip "todo"
  end

  def test_radio_button_tag
    skip "todo"
  end

  def test_range_field_tag
    skip "todo"
  end

  def test_search_field_tag
    skip "todo"
  end

  def test_select_tag
    skip "todo"
  end

  def test_submit_tag
    skip "todo"
  end

  def test_telephone_field_tag
    skip "todo"
  end

  def test_text_area_tag
    skip "todo"
  end

  def test_text_field_tag
    skip "todo"
  end

  # TODO: test min, max, step attributes
  # TODO: test with Date, Time and timestamps attribute values
  def test_time_field_tag
    assert_equal %(<input name="ring_at" type="time"/>), time_field_tag(:ring_at)
    assert_equal %(<input id="post_ring_at" name="ring_at" type="time" value="10:34"/>),
      time_field_tag(:ring_at, "10:34", { id: "post_ring_at" })
  end

  def test_url_field_tag
    skip "todo"
  end

  def test_week_field_tag
    skip "todo"
  end
end
