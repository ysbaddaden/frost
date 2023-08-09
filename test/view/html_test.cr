require "./test_helpers"

describe "Frost::HTML" do
  include Frost::View::TestHelpers

  describe "registered elements" do
    struct Example < Frost::HTML
      def initialize(@name : String, @content : String? = nil)
      end

      def template
        {% begin %}
        case @name
        {% for name in Frost::HTML::ELEMENTS %}
        when {{name}}
          if content = @content
            self.{{name.id}}(content)
          else
            self.{{name.id}}
          end
        {% end %}
        when "template_tag"
          if content = @content
            template_tag(content)
          else
            template_tag
          end
        {% for name in Frost::HTML::VOID_ELEMENTS %}
        when {{name}}
          self.{{name.id}}
        {% end %}
        else
          raise "unknown HTML element #{@name}"
        end
        {% end %}
      end

      def template(&block)
        {% begin %}
        case @name
        {% for name in Frost::HTML::ELEMENTS %}
        when {{name}}
          self.{{name.id}} { yield }
        {% end %}
        when "template_tag"
          template_tag { yield }
        else
          raise "unknown HTML element #{@name}"
        end
        {% end %}
      end
    end

    it "renders elements" do
      assert_equal %(<template></template>), render(Example.new("template_tag"))
      assert_equal %(<template>data</template>), render(Example.new("template_tag", "data"))
      assert_equal %(<template>contents</template>), render(Example.new("template_tag")) { "contents" }

      {% for name in Frost::HTML::ELEMENTS %}
        assert_equal %(<{{name.id}}></{{name.id}}>), render(Example.new({{name}}))
        assert_equal %(<{{name.id}}>data</{{name.id}}>), render(Example.new({{name}}, "data"))
        assert_equal %(<{{name.id}}>contents</{{name.id}}>), render(Example.new({{name}})) { "contents" }
      {% end %}
    end

    it "renders void elements" do
      {% for name in Frost::HTML::VOID_ELEMENTS %}
        assert_equal %(<{{name.id}}/>), render(Example.new({{name}}))
      {% end %}
    end

    it "template_tag" do
    end
  end

  describe "content_type" do
    struct Example < Frost::HTML
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

  describe "view within layout" do
    struct Layout < Frost::HTML
      def initialize(@title : String)
      end

      def template(&) : Nil
        doctype
        html do
          head { title(@title) }
          body { yield }
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

    it "renders" do
      assert_equal %(<!DOCTYPE html><html><head><title>website</title></head><body><h1>hello <strong>world</strong></h1></body></html>),
        render(Example.new)
    end
  end

  describe "nested components" do
    struct NavLink < Frost::HTML
      def initialize(@text : String, @to : String)
      end

      def template
        li { a(href: @to) { @text } }
      end
    end

    struct Nav < Frost::HTML
      def template(&)
        nav { ul { yield } }
      end
    end

    struct Example < Frost::HTML
      def template
        render Nav.new do
          render NavLink.new("Home", to: "/")
          render NavLink.new("Posts", to: "/posts")
        end
      end
    end

    it "renders" do
      assert_equal %(<nav><ul><li><a href="/">Home</a></li><li><a href="/posts">Posts</a></li></ul></nav>),
        render(Example.new)
    end
  end
end
