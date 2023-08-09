module Frost
  abstract struct HTML < DOM
    PREFERS_CLOSED_ELEMENTS = false

    ELEMENTS = %w[
      html head style title body address article aside footer header h1 h2 h3 h4
      h5 h6 main nav section blockquote dd div dl dt figcaption figure li menu
      ol p pre ul a abbr b bdi bdo cite code data dfn em i kbd mark q rt ruby s
      samp small span strong sub sup time u var audio map video iframe object
      picture portal svg math canvas noscript script del ins caption colgroup
      table tbody td tfoot th thead tr button datalist fieldset form label
      legend meter optgroup progress select textarea details dialog summary slot
    ]
    VOID_ELEMENTS = %w[
      base link meta hr br wbr area img track embed source col input
    ]

    {% for name in ELEMENTS %}
      register_element {{name}}
    {% end %}

    {% for name in VOID_ELEMENTS %}
      register_void_element {{name}}
    {% end %}

    register_element "template", as: "template_tag"

    # Outputs the HTML5 doctype.
    def doctype : Nil
      @__io__ << "<!DOCTYPE html>"
    end

    def content_type : String
      "text/html; charset=utf-8"
    end
  end
end
