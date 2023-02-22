require "./test_helpers"

describe "Frost::HTML" do
  include Frost::View::TestHelpers

  describe "content_type" do
    struct Example < Frost::HTML
      def template
      end
    end

    it "returns the HTML mimetype" do
      assert_equal "text/html; charset=utf-8", Example.new.content_type
    end
  end

  describe "doctype" do
    struct Example < Frost::HTML
      def template
        doctype
      end
    end

    it "renders the HTML5 doctype" do
      assert_equal "<!DOCTYPE html>", render Example.new
    end
  end

  describe "element" do
    struct Example < Frost::HTML
      def template
        a(href: "/url", class: %w[link is-active], "data-escapes": %(&<>"'), data: { action: "ctrl->call" }) { "text" }
      end
    end

    it "renders safe HTML" do
      assert_equal %(<a href="/url" class="link is-active" data-escapes="&amp;&lt;&gt;&quot;&apos;" data-action="ctrl-&gt;call">text</a>),
        render Example.new
    end
  end

  describe "void element" do
    struct Example < Frost::HTML
      def template
        link(href: "/url", class: %w[link is-active], "data-escapes": %(&<>"'), data: { action: "ctrl->call" })
      end
    end

    it "renders safe HTML" do
      assert_equal %(<link href="/url" class="link is-active" data-escapes="&amp;&lt;&gt;&quot;&apos;" data-action="ctrl-&gt;call"/>),
        render Example.new
    end
  end

  describe "nested" do
    struct Layout < Frost::HTML
      def initialize(@title : String)
      end

      def template(&block) : Nil
        doctype
        html do
          head { title(@title) }
          body(&block)
        end
      end
    end

    struct Example < Frost::HTML
      def template : Nil
        render Layout.new(title: "website") do
          h1 do
            concat "hello "
            strong "world"
          end
        end
      end
    end

    it "renders view within layout" do
      assert_equal %(<!DOCTYPE html><html><head><title>website</title></head><body><h1>hello <strong>world</strong></h1></body></html>),
        render(Example.new)
    end
  end
end
