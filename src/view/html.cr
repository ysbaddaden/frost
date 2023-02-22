module Frost
  abstract struct HTML < DOM
    PREFERS_CLOSED_ELEMENTS = false

    # main root

    register_element "html"

    # document metadata

    register_void_element "base"
    register_element "head"
    register_void_element "link"
    register_void_element "meta"
    register_element "style"
    register_element "title"

    # sectioning root

    register_element "body"

    # content sectioning

    register_element "address"
    register_element "article"
    register_element "aside"
    register_element "footer"
    register_element "header"
    register_element "h1"
    register_element "h2"
    register_element "h3"
    register_element "h4"
    register_element "h5"
    register_element "h6"
    register_element "main"
    register_element "nav"
    register_element "section"

    # text content

    register_element "blockquote"
    register_element "dd"
    register_element "div"
    register_element "dl"
    register_element "dt"
    register_element "figcaption"
    register_element "figure"
    register_void_element "hr"
    register_element "li"
    register_element "menu"
    register_element "ol"
    register_element "p"
    register_element "pre"
    register_element "ul"

    # inline text semantics

    register_element "a"
    register_element "abbr"
    register_element "b"
    register_element "bdi"
    register_element "bdo"
    register_void_element "br"
    register_element "cite"
    register_element "code"
    register_element "data"
    register_element "dfn"
    register_element "em"
    register_element "i"
    register_element "kbd"
    register_element "mark"
    register_element "q"
    register_element "rt"
    register_element "ruby"
    register_element "s"
    register_element "samp"
    register_element "small"
    register_element "span"
    register_element "strong"
    register_element "sub"
    register_element "sup"
    register_element "time"
    register_element "u"
    register_element "var"
    register_void_element "wbr"

    # image and multimedia

    register_void_element "area"
    register_element "audio"
    register_void_element "img"
    register_element "map"
    register_void_element "track"
    register_element "video"

    # embedded content

    register_void_element "embed"
    register_element "iframe"
    register_element "object"
    register_element "picture"
    register_element "portal"
    register_void_element "source"

    # SVG and MathML

    register_element "svg"
    register_element "math"

    # scripting

    register_element "canvas"
    register_element "noscript"
    register_element "script"
    register_element "del"
    register_element "ins"

    # table content

    register_element "caption"
    register_void_element "col"
    register_element "colgroup"
    register_element "table"
    register_element "tbody"
    register_element "td"
    register_element "tfoot"
    register_element "th"
    register_element "thead"
    register_element "tr"

    # forms

    register_element "button"
    register_element "datalist"
    register_element "fieldset"
    register_element "form"
    register_void_element "input"
    register_element "label"
    register_element "legend"
    register_element "meter"
    register_element "optgroup"
    register_element "progress"
    register_element "select"
    register_element "textarea"

    # interactive elements

    register_element "details"
    register_element "dialog"
    register_element "summary"

    # web components

    register_element "slot"
    register_element "template"

    # Outputs the HTML5 doctype.
    def doctype : Nil
      @__io__ << "<!DOCTYPE html>"
    end

    def content_type : String
      "text/html; charset=utf-8"
    end
  end
end
