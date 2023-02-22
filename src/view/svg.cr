module Frost
  abstract struct SVG < DOM
    PREFERS_CLOSED_ELEMENTS = true

    # animation

    register_element "animate"
    register_element "animateMotion"
    register_element "animateTransform"
    register_element "discard"
    register_element "mpath"
    register_element "set"

    # container

    register_element "a"
    register_element "defs"
    register_element "g"
    register_element "marker"
    register_element "mask"
    register_element "svg"
    register_element "switch"
    register_element "symbol"

    # descriptive

    register_element "desc"
    register_element "metadata"
    register_element "title"

    # filter primitive

    register_element "feBlend"
    register_element "feColorMatrix"
    register_element "feComponentTransfer"
    register_element "feComposite"
    register_element "feConvolveMatrix"
    register_element "feDiffuseLighting"
    register_element "feDisplacementMap"
    register_element "feDropShadow"
    register_element "feFlood"
    register_element "feFuncA"
    register_element "feFuncB"
    register_element "feFuncG"
    register_element "feFuncR"
    register_element "feGaussianBlur"
    register_element "feImage"
    register_element "feMerge"
    register_element "feMergeNode"
    register_element "feMorphology"
    register_element "feOffset"
    register_element "feSpecularLighting"
    register_element "feTile"
    register_element "feTurbulence"

    # gradient

    register_element "linearGradient"
    register_element "radialGradient"
    register_element "stop"

    # graphics

    register_element "circle"
    register_element "ellipse"
    register_element "image"
    register_element "line"
    register_element "path"
    register_element "polygon"
    register_element "polyline"
    register_element "rect"
    register_element "text"

    # graphics referencing

    register_element "use"

    # light source

    register_element "feDistantLight"
    register_element "fePointLight"
    register_element "feSpotLight"

    # paint server

    register_element "hatch"
    register_element "pattern"
    register_element "solidcolor"

    # text

    register_element "textPath"
    register_element "text"
    register_element "tspan"

    # uncategorized

    register_element "clipPath"
    register_element "filter"
    register_element "hatchpath"
    register_element "script"
    register_element "style"
    register_element "view"

    def content_type : String
      "image/svg+xml; charset=utf-8"
    end
  end
end
