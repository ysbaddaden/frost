module Frost
  class View
    class Error < Exception
    end

    # Raised when trying to render a template that doesn't exist.
    class MissingTemplate < Error
      def initialize(path, action, format)
        super "no template #{ action.inspect } with format #{ format.inspect } found in #{ path }\")\n"
      end
    end
  end
end
