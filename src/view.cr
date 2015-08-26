require "./view/errors"
require "./view/helpers/*"

module Trail
  DEFAULT_FORMAT = "html"

  # TODO: render partial (include the partial into the processed template)
  # TODO: XSS protection (escape by default + String#html_safe!)
  abstract class View
    include CaptureHelper
    include TagHelper
    include UrlHelper
    include FormTagHelper

    def initialize(@controller)
    end

    forward_missing_to @controller

    abstract def render(action, format = DEFAULT_FORMAT, &block)

    def render(action, format = DEFAULT_FORMAT)
      render(action, format) {}
    end

    # :nodoc:
    macro generate_render_methods
      {{ run "./view/prepare.cr", Trail::VIEWS_PATH, @type.name }}
    end

    macro inherited
      generate_render_methods
    end
  end
end
