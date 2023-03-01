require "./view/test_helpers"

class Frost::ViewTest < Minitest::Test
  include View::TestHelpers

  struct Example < Frost::View
    def template
      @__io__ << "contents"
    end

    def template(&)
      @__io__ << "before "
      yield
      @__io__ << " after"
    end
  end

  def test_template
    assert_equal "contents", render(Example.new)
  end

  def test_template_with_block
    io = IO::Memory.new
    html = render(io, Example.new) { io << "block" }
    assert_equal "before block after", html
  end
end
