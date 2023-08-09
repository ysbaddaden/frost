require "./test_helpers"

describe "Frost::DOM" do
  include Frost::View::TestHelpers

  describe "register_element" do
    struct Example < Frost::DOM
      register_element :content

      def template
        content(href: "/url", class: %w[link is-active], "data-escapes": %(&<>"'), data: { action: "ctrl->call" }) { "text" }
      end
    end

    it "renders safe DOM" do
      assert_equal %(<content href="/url" class="link is-active" data-escapes="&amp;&lt;&gt;&quot;&apos;" data-action="ctrl-&gt;call">text</content>),
        render Example.new
    end
  end

  describe "prefers closing elements" do
    struct Example < Frost::DOM
      PREFERS_CLOSED_ELEMENTS = false
      register_element :content

      def template
        content(href: "/url")
      end
    end

    it "renders" do
      assert_equal %(<content href="/url"></content>), render Example.new
    end
  end

  describe "prefers closed elements" do
    struct Example < Frost::DOM
      PREFERS_CLOSED_ELEMENTS = true

      register_element :content

      def template
        content(href: "/url")
      end
    end

    it "renders" do
      assert_equal %(<content href="/url"/>), render Example.new
    end
  end

  describe "register_void_element" do
    struct Example < Frost::DOM
      register_void_element :tag

      def template
        tag(href: "/url", class: %w[link is-active], "data-escapes": %(&<>"'), data: { action: "ctrl->call" })
      end
    end

    it "renders safe DOM" do
      assert_equal %(<tag href="/url" class="link is-active" data-escapes="&amp;&lt;&gt;&quot;&apos;" data-action="ctrl-&gt;call"/>),
        render Example.new
    end
  end

  describe "boolean attributes" do
    struct Example < Frost::DOM
      register_void_element :input

      def initialize(@value : Bool)
      end

      def template
        input(type: "radio", checked: @value)
      end
    end

    it "renders attribute when true" do
      assert_equal %(<input type="radio" checked/>), render(Example.new(true))
    end

    it "skips attribute when false" do
      assert_equal %(<input type="radio"/>), render(Example.new(false))
    end
  end

  describe "escapes contents" do
    struct Example < Frost::DOM
      register_element :tag

      def template
        tag %(<site> & "quotes'")
      end
    end

    it "direct value" do
      assert_equal "<tag>&lt;site&gt; &amp; &quot;quotes&apos;&quot;</tag>", render Example.new
    end
  end

  describe "escapes block returned contents" do
    struct Example < Frost::DOM
      register_element :tag

      def template
        tag { %(<site> & "quotes'") }
      end
    end

    it "direct value" do
      assert_equal "<tag>&lt;site&gt; &amp; &quot;quotes&apos;&quot;</tag>", render Example.new
    end
  end

  describe "concat" do
    struct Example < Frost::DOM
      def initialize(@value : String | Symbol | Int32 | Time)
      end

      def template
        concat @value
      end
    end

    it "appends" do
      assert_equal "value", render(Example.new("value"))
      assert_equal "contents", render(Example.new(:contents))
      assert_equal "123", render(Example.new(123))
      assert_equal "2023-01-12 00:00:00 UTC", render(Example.new(Time.utc(2023, 1, 12)))
    end

    it "escapes" do
      assert_equal "&amp; &lt; &gt; &quot; &apos;", render(Example.new(%(& < > " ')))
    end
  end

  describe "unsafe_raw" do
    struct Example < Frost::DOM
      def initialize(@value : String)
      end

      def template
        unsafe_raw @value
      end
    end

    it "appends" do
      assert_equal "value", render(Example.new("value"))
    end

    it "doesn't escape" do
      assert_equal %(& < > " '), render(Example.new(%(& < > " ')))
    end
  end

  describe "comment" do
    struct Example < Frost::DOM
      def template
        comment "some comment data"
      end
    end

    it "renders" do
      assert_equal "<!--some comment data-->", render(Example.new)
    end
  end

  describe "whitespace" do
    struct Example < Frost::DOM
      def template
        whitespace
      end

      def template(&block)
        whitespace(&block)
      end
    end

    it "appends a whitespace" do
      assert_equal " ", render(Example.new)
    end

    it "appends a whitespace before and after the block" do
      io = IO::Memory.new
      html = render(io, Example.new) { io << "block" }
      assert_equal " block ", html
    end
  end
end
