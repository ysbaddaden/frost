require "./test_helper"

class Frost::ViewTest < Minitest::Test
  class PostController < Frost::Controller
    def index
      render :index
    end

    def show
      render :show
    end

    def missing_template
      render :missing_template
    end
  end

  def test_generates_view_from_controller
    typeof(::Frost::ViewTest::PostView)
    # assert_equal "frost/view_test/post", PostView::VIEW_PATH
  end

  def test_generates_render_methods
    # type the controller methods so crystal will execute macros and generate
    # the expected view methods:
    typeof(new_controller.index)
    typeof(new_controller.show)
    typeof(new_controller.missing_template)

    view = new_view("index")
    assert_responds_to view, :index
    assert_responds_to view, :show
    assert_responds_to view, :missing_template
  end

  def test_delegates_to_controller
    controller = new_controller("index")
    view = PostView.new(controller)

    assert_equal "frost/view_test/post", view.controller_path
    assert_equal "post", view.controller_name
    assert_equal "index", view.action_name

    assert_same controller, view.controller
    assert_same controller.context, view.context
    assert_equal controller.request, view.request
    assert_same controller.response, view.response
    assert_same controller.params, view.params
  end

  def test_raises_on_missing_template
    assert_raises(Frost::MissingTemplateError) do
      new_view.missing_template
    end

    assert_raises(Frost::MissingTemplateError) do
      new_view.layout("missing_layout")
    end

    assert_raises(Frost::MissingTemplateError) do
      new_view.layout("application", format: "unknown") {}
    end
  end

  def test_renders_ecr_templates
    assert_equal "POSTS/INDEX\n", render("index", format: "text")
    assert_equal "POSTS/SHOW\n", render("show", format: "text")
  end

  def test_renders_ecr_templates_in_layout
    assert_equal "BEFORE\nPOSTS/INDEX\n\nAFTER\n",
      render("index", layout: "application", format: "text")

    assert_equal "EMPTY: POSTS/INDEX\n\n",
      render("index", layout: "empty", format: "text")
  end

  def test_escapes_unsafe_html
    html = render("index", layout: "application")

    # it didn't escape the raw template:
    assert_match "<!DOCTYPE html>", html
    assert_match "<html>", html
    assert_match "<body>", html

    # it escaped the untrusted string:
    refute_match /<a href="\/malware">/, html
    assert_match /&lt;a href=&quot;\/malware&quot;&gt;/, html

    # it didn't escape the trusted string:
    assert_match /<a href="\/safe">/, html
    refute_match /&lt;a href=&quot;\/safe&quot;&gt;/, html
  end

  macro render(action, layout = false, format = "html")
    capture_body do
      view = new_view

      if {{layout}}
        view.layout({{layout}}, {{format}}) do
          view.{{action.id}}({{format}})
        end
      else
        view.{{action.id}}({{format}})
      end
    end
  end

  private def capture_body
    capture { yield }.body
  end

  private def capture
    @io = io = IO::Memory.new
    yield
    @response.try(&.close)
    HTTP::Client::Response.from_io(io.rewind)
  end

  private def new_view(action_name = "")
    PostView.new(new_controller(action_name))
  end

  private def new_controller(action_name = "")
    request = HTTP::Request.new("GET", "/post/123")
    @response = response = HTTP::Server::Response.new(@io ||= IO::Memory.new)
    context = HTTP::Server::Context.new(request, response)
    PostController.new(context, Routes::Params.new, action_name)
  end
end
