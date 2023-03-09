require "minitest/autorun"
require "xml"
require "../../src/css/selectors"

class Frost::CSS::Selectors2Test < Minitest::Test
  struct DOM
    def initialize(html : String)
      @xml = XML.parse_html(html)
    end

    def css(selector : String)
      xpath(Selectors.to_xpath(selector))
    end

    def xpath(selector : String)
      @xml.xpath_nodes(selector).map do |node|
        if id = node["id"]?
          "#{node.name}##{id}"
        else
          node.name
        end
      end
    end
  end

  def test_universal_selector
    dom = DOM.new <<-HTML
      <html>
      <body>
        <p></p>
        <a></a>
        <img/>
      </body>
      </html>
    HTML
    assert_equal %w[html body p a img], dom.css("*")
    assert_equal %w[html body p a img], dom.css("  \r\n\f \t * \t")
  end

  def test_type_selector
    dom = DOM.new <<-HTML
      <html>
      <body>
        <p id="a"></p>
        <p id="b"><img/></p>
      </body>
      </html>
    HTML
    assert_equal %w[p#a p#b], dom.css("p")
    assert_equal %w[img], dom.css("img")
    assert_empty dom.css("nav")
  end

  def test_attribute_presence_and_value_selector
    dom = DOM.new <<-HTML
      <html>
      <body>
        <p id="a" class="value"></p>
        <div>
          <p id="b" class="other value"><img/></p>
        </div>
        <p id="c" class="some other"></p>
        <p id="d" data-id="some"></p>
        <p id="e" data-id="some-value"></p>
      </body>
      </html>
    HTML

    assert_equal %w[p#a p#b p#c], dom.css("p[class]")
    assert_empty dom.css("p[data]")

    assert_equal %w[p#a], dom.css("p[class='value']")
    assert_empty dom.css("p[class='val2']")

    assert_equal %w[p#b p#c], dom.css("p[class~='other']")
    assert_empty dom.css("p[class~='valueable']")

    assert_equal %w[p#d p#e], dom.css("p[data-id|='some']")
    assert_empty dom.css("p[data-id|='value']")
  end

  def test_substring_matching_attribute_selectors
    dom = DOM.new <<-HTML
      <html>
      <body>
        <p id="a" name="val1"></p>
        <div>
          <p id="b" name="val21"><img/></p>
        </div>
        <p id="c" name="other21"></p>
        <p></p>
      </body>
      </html>
    HTML

    assert_equal %w[p#a p#b], dom.css("p[name^='val']")
    assert_empty dom.css("p[name^='what']")

    assert_equal %w[p#b p#c], dom.css("p[name$='21']")
    assert_empty dom.css("p[name$='a21']")

    assert_equal %w[p#b p#c], dom.css("p[name*='2']")
    assert_empty dom.css("p[name*='what']")
  end

  def test_id_selector
    dom = DOM.new <<-HTML
      <html>
      <body>
        <p id="a"></p>
        <p id="b"><img/></p>
      </body>
      </html>
    HTML
    assert_equal %w[p#a], dom.css("#a")
    assert_equal %w[p#b], dom.css("p#b")
    assert_empty dom.css("#c")
    assert_empty dom.css("a#a")
  end

  def test_class_selector
    dom = DOM.new <<-HTML
      <nav>
        <ul>
          <li id="1" class="active"></li>
          <li id="2" class="inactive"></li>
          <li id="3"></li>
        </ul>
      </nav>
    HTML
    assert_equal %w[li#1], dom.css(".active")
    assert_equal %w[li#2], dom.css("li.inactive")
    assert_empty dom.css(".unknown")
  end

  def test_logical_combinations
    dom = DOM.new <<-HTML
      <html>
      <body>
        <nav>
          <ul id="0">
            <li id="1" class="active"></li>
            <li id="2" class="inactive"></li>
            <li id="3"></li>
          </ul>
          <ul id="4">
            <li id="5"></li>
          </ul>
        </nav>
      </body>
      </html>
    HTML
    assert_equal %w[li#2 li#3 li#5], dom.css("li:not(.active)")
    assert_equal %w[nav ul#0 li#1 li#3 ul#4 li#5], dom.css("body :not(.inactive)")
    assert_equal %w[ul#0], dom.css("ul:has(li.active)")
    assert_equal %w[ul#4], dom.css("ul:not(:has(.active))")

    skip "generates invalid xpath when nesting :not() inside :has()"
    assert_equal %w[ul#4], dom.css("ul:has(:not(.active))")
  end

  def test_input_pseudo_classes
    dom = DOM.new <<-HTML
      <html>
      <body>
        <input id="c1" checked required/>
        <input id="c2"/>

        <select>
          <option id="o1"></option>
          <option id="o2" selected></option>
        </select>

        <input id="e1" disabled/>
        <input id="e2" required/>

        <input id="r1"/>
        <input id="r2" readonly/>

        <textarea id="t1" required></textarea>
        <textarea id="t2" disabled></textarea>

        <button id="b1" disabled></button>
        <button id="b2"></button>
      </html>
      </body>
    HTML

    assert_equal %w[input#c1 option#o2], dom.css(":checked")

    assert_equal %w[input#c1 input#c2 select option#o1 option#o2 input#e2 input#r1 input#r2 textarea#t1 button#b2], dom.css(":enabled")
    assert_equal %w[input#e1 textarea#t2 button#b1], dom.css(":disabled")

    assert_equal %w[input#c1 input#e2 textarea#t1], dom.css(":required")
    assert_equal %w[input#c2 select input#e1 input#r1 input#r2 textarea#t2], dom.css(":optional")
  end

  TREE_STRUCTURAL_HTML = <<-HTML
    <html>
    <head></head>
    <body>
      <table id="table">
        <tr id="line-1">
          <td id="cell-1-1"></td>
          <td id="cell-1-2"></td>
          <td id="cell-1-3"></td>
          <td id="cell-1-4"></td>
          <td id="cell-1-5"></td>
          <td id="cell-1-6"></td>
          <td id="cell-1-7"></td>
          <td id="cell-1-8"></td>
          <td id="cell-1-9"></td>
          <td id="cell-1-10"></td>
          <td id="cell-1-11"></td>
        </tr>
        <tr id="line-2">
          <td id="cell-2-1"></td>
          <td id="cell-2-2"></td>
          <td id="cell-2-3"></td>
          <td id="cell-2-4"></td>
          <td id="cell-2-5"></td>
          <td id="cell-2-6"></td>
          <td id="cell-2-7"></td>
          <td id="cell-2-8"></td>
          <td id="cell-2-9"></td>
          <td id="cell-2-10"></td>
          <td id="cell-2-11"></td>
        </tr>
      </table>

      <div id="div1" class="foo bar one">
        <p id="1"></p>
        <ul id="2"></ul>
        <ul id="4"></ul>
        <p id="3"></p>
        <p id="5"></p>
      </div>

      <div id="div2">
        <p id="alone"></p>
      </div>

      <div id="div3">
        <ul id="ul-only-of-type"></ul>
        <p id="p-only-of-type"></p>
      </div>
    </body>
    </html>
  HTML


  def test_tree_structural_pseudo_classes
    dom = DOM.new(TREE_STRUCTURAL_HTML)

    assert_equal %w[p#1 ul#2 ul#4 p#3 p#5], dom.css("#div1 :empty")
    assert_empty dom.css("div:empty")

    # :root (?)
  end

  def test_child_indexed_pseudo_classes
    dom = DOM.new(TREE_STRUCTURAL_HTML)

    assert_equal %w[tr#line-1 td#cell-1-1 td#cell-2-1], dom.css("table :first-child")
    assert_equal %w[td#cell-1-11 tr#line-2 td#cell-2-11], dom.css("table :last-child")
    assert_equal %w[html p#alone], dom.css(":only-child")
    assert_empty dom.css("td:only-child")

    assert_equal %w[p#1 p#alone p#p-only-of-type], dom.css("p:first-of-type")
    assert_equal %w[p#5 p#alone p#p-only-of-type], dom.css("p:last-of-type")
    assert_equal %w[p#alone p#p-only-of-type], dom.css("p:only-of-type")
    assert_empty dom.css("td:only-of-type")

    assert_equal %w[p#1 p#alone], dom.css("p:nth-child(1)")
    assert_equal %w[td#cell-1-4 td#cell-2-4], dom.css("td:nth-child(4)")
    assert_equal %w[ul#4], dom.css("div :nth-child(3)")

    odd = %w[
      td#cell-1-1
      td#cell-1-3
      td#cell-1-5
      td#cell-1-7
      td#cell-1-9
      td#cell-1-11
    ]
    assert_equal odd, dom.css("#line-1 :nth-child(odd)")
    assert_equal odd, dom.css("#line-1 :nth-child(2n+1)")

    even = %w[
      td#cell-1-2
      td#cell-1-4
      td#cell-1-6
      td#cell-1-8
      td#cell-1-10
    ]
    assert_equal even, dom.css("#line-1 :nth-child(even)")
    assert_equal even, dom.css("#line-1 :nth-child(2n)")
    assert_equal even, dom.css("#line-1 :nth-child(2n+0)")

    assert_equal %w[td#cell-1-5 td#cell-1-10], dom.css("#line-1 :nth-child(5n)")
    assert_equal %w[td#cell-1-1 td#cell-1-6 td#cell-1-11], dom.css("#line-1 :nth-child(5n+1)")
    assert_equal %w[td#cell-1-6 td#cell-1-11], dom.css("#line-1 :nth-child(5n+6)")
    assert_equal %w[td#cell-1-4 td#cell-1-9], dom.css("#line-1 :nth-child(5n-1)")
    assert_equal %w[td#cell-1-4 td#cell-1-9], dom.css("#line-1 :nth-child(5n-6)")

    assert_empty dom.css("#line-1 :nth-child(-1)")
    assert_empty dom.css("#line-1 :nth-child(-2n)")
    assert_equal %w[td#cell-1-2 td#cell-1-5 td#cell-1-8], dom.css("#line-1 :nth-child(-3n+8)")
    assert_empty dom.css("#line-1 :nth-child(-5n+0)")
    assert_equal %w[td#cell-1-1], dom.css("#line-1 :nth-child(-5n+1)")
    assert_equal %w[td#cell-1-1 td#cell-1-6], dom.css("#line-1 :nth-child(-5n+6)")
    assert_equal %w[td#cell-1-5 td#cell-1-10], dom.css("#line-1 :nth-child(-5n+10)")
    assert_empty dom.css("#line-1 :nth-child(-5n-1)")
    assert_empty dom.css("#line-1 :nth-child(-5n-10)")

    assert_equal %w[td#cell-1-8], dom.css("#line-1 :nth-last-child(4)")
    assert_empty dom.css("#line-1 :nth-last-child(-4)")

    assert_equal odd, dom.css("#line-1 :nth-last-child(odd)")
    assert_equal odd, dom.css("#line-1 :nth-last-child(2n+1)")
    assert_equal even, dom.css("#line-1 :nth-last-child(even)")
    assert_equal even, dom.css("#line-1 :nth-last-child(2n)")

    assert_equal %w[td#cell-1-3 td#cell-1-6 td#cell-1-9], dom.css("#line-1 :nth-last-child(3n)")
    assert_equal %w[td#cell-1-2 td#cell-1-7], dom.css("#line-1 :nth-last-child(5n)")
    assert_equal %w[td#cell-1-1 td#cell-1-6 td#cell-1-11], dom.css("#line-1 :nth-last-child(5n+1)")
    assert_equal %w[td#cell-1-1 td#cell-1-6], dom.css("#line-1 :nth-last-child(5n+6)")
    assert_equal %w[td#cell-1-3 td#cell-1-8], dom.css("#line-1 :nth-last-child(5n-1)")
    assert_equal %w[td#cell-1-5 td#cell-1-10], dom.css("#line-1 :nth-last-child(5n-3)")
    assert_equal %w[td#cell-1-3 td#cell-1-8], dom.css("#line-1 :nth-last-child(5n-6)")
    assert_empty dom.css("#line-1 :nth-last-child(-5n-1)")
    assert_empty dom.css("#line-1 :nth-last-child(-5n-6)")
  end

  def test_typed_child_indexed_pseudo_classes
    dom = DOM.new(TREE_STRUCTURAL_HTML)

    assert_equal %w[p#1 p#alone p#p-only-of-type], dom.css("p:nth-of-type(1)")
    assert_equal %w[p#3], dom.css("p:nth-of-type(even)")
    assert_equal %w[p#1 p#5 p#alone p#p-only-of-type], dom.css("p:nth-of-type(odd)")

    assert_equal %w[p#5 p#alone p#p-only-of-type], dom.css("p:nth-last-of-type(1)")
    assert_equal %w[p#3], dom.css("p:nth-last-of-type(2)")
    assert_equal %w[p#3], dom.css("p:nth-last-of-type(even)")
    assert_equal %w[p#1 p#5 p#alone p#p-only-of-type], dom.css("p:nth-last-of-type(odd)")

    skip ":nth-of-type(An)"
    skip ":nth-of-type(An+B)"
    skip ":nth-of-type(An-B)"
    skip ":nth-of-type(-An+B)"

    skip ":nth-last-of-type(An)"
    skip ":nth-last-of-type(An+B)"
    skip ":nth-last-of-type(An-B)"
    skip ":nth-last-of-type(-An+B)"
  end

  def test_descendant_combinator
    dom = DOM.new <<-HTML
      <ul>
        <li><a/></li>
        <li></li>
      </ul>"
    HTML
    assert_equal %w[a], dom.css("ul li a")
    assert_equal %w[a], dom.css("ul \t  a")
    assert_equal %w[li a li], dom.css("ul *")
    assert_empty dom.css("dl a")
  end

  def test_child_combinator
    dom = DOM.new <<-HTML
      <ul>
        <li><a/></li>
        <li></li>
      </ul>"
    HTML
    assert_equal %w[a], dom.css("li>a")
    assert_equal %w[li li], dom.css("ul > *")
    assert_empty dom.css("ul > a")
    assert_empty dom.css("dl > a")
  end

  def test_next_sibling_combinator
    dom = DOM.new <<-HTML
      <div>
        <span id="1"></span>
        <p><a id="2"></a></p>
        <a id="3"></a>
        <span id="4">
          <a id="5"></a>
        </span>
      </div>
    HTML
    assert_equal %w[a#3], dom.css("p~a")
    assert_equal %w[a#3], dom.css("span ~ a")
    assert_equal %w[span#4], dom.css("p ~ span")
    assert_equal %w[span#4], dom.css("span ~ span")
    assert_equal %w[p a#3 span#4], dom.css("span ~ *")
    assert_empty dom.css("div ~ a")
    assert_empty dom.css("a ~ p")
  end

  def test_subsequent_sibling_combinator
    dom = DOM.new <<-HTML
      <div>
        <span id="1"></span>
        <p><a id="2"></a></p>
        <a id="3"></a>
        <span id="4">
          <a id="5"></a>
        </span>
      </div>
      <div>
        <p></p>
        <a id="6"></a>
      </div>
    HTML
    assert_equal %w[p], dom.css("span+p")
    assert_equal %w[a#3 a#6], dom.css("p +a")
    assert_equal %w[span#4], dom.css("a + span")
    assert_empty dom.css("span + a")
  end
end
