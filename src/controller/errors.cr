module Frost
  class Controller
    class Error < Exception
    end

    # Raised when trying to render whereas the controller already rendered or
    # redirected or skipped rendering (using `head status`).
    class DoubleRenderError < Error
    end
  end
end

