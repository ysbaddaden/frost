require "./route"

module Trail
  module Routing
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
