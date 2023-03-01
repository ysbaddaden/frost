module Frost
  abstract struct SVG < DOM
    PREFERS_CLOSED_ELEMENTS = true

    ELEMENTS = %w[
      animate animateMotion animateTransform discard mpath set a defs g marker
      mask svg switch symbol desc metadata title feBlend feColorMatrix
      feComponentTransfer feComposite feConvolveMatrix feDiffuseLighting
      feDisplacementMap feDropShadow feFlood feFuncA feFuncB feFuncG feFuncR
      feGaussianBlur feImage feMerge feMergeNode feMorphology feOffset
      feSpecularLighting feTile feTurbulence linearGradient radialGradient stop
      circle ellipse image line path polygon polyline rect use feDistantLight
      fePointLight feSpotLight hatch pattern solidcolor textPath text tspan
      clipPath filter hatchpath script style view
    ]

    {% for name in ELEMENTS %}
      register_element {{name}}
    {% end %}

    def content_type : String
      "image/svg+xml; charset=utf-8"
    end
  end
end
