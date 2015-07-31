require "ecr/macros"
require "./view/errors"

module Trail
  DEFAULT_FORMAT = "html"

  # TODO: render partial (for this view or another one)
  abstract class View
    def initialize(@controller)
    end

    forward_missing_to @controller

    abstract def render(action, format = DEFAULT_FORMAT)

    # :nodoc:
    macro generate_render_methods
      {{ run "./view/prepare.cr", Trail::VIEWS_PATH, @type.name }}
    end

    macro inherited
      generate_render_methods
    end
  end
end
