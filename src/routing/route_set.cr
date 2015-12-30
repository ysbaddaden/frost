require "./route"

module Frost
  module Routing
    # FIXME: fixes https://github.com/ysbaddaden/frost/issues/1#issuecomment-167912888
    #        by forcing the compiler to know about the Route instance variable
    #        types, when no routes have been defined.
    #        This should be removed when the new compiler is released.
    typeof(Route.new("", "", "", "", nil))

    # :nodoc:
    class RouteSet < Array(Route)
      def push(path, controller, action, via = :all, as = nil)
        via = [via] unless via.responds_to?(:each)

        via.each do |method|
          push Route.new(method.to_s, path, controller, action, as)
        end
      end
    end
  end
end
