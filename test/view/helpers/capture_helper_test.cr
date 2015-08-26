require "../../test_helper"
require "../../../src/view/ecr/ecr"

class Trail::View::CaptureHelperTest < Minitest::Test
  include Trail::View::CaptureHelper
  include Trail::View::TagHelper

  def test_capture
    assert_equal "test1", capture { "test1" }
    assert_equal "test2", capture { __buf__ << "test2" }
    assert_equal "test3", capture { __buf__ << "test3"; "skipped" }
  end

  def test_capture_in_ecr_template
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
