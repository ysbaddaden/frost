module Frost
  module Routing
    # :nodoc:
    class Route
      FIND_PARAM_NAME = /[*:]([\w\d_]+)/

      property :path, :method, :controller, :action, :route_name

      def initialize(@method : String, @path : String, @controller : String, @action : String, @route_name = nil : String?)
        # FIXME: types are defined to avoid a compiler bug with an empty route set
        #        see https://github.com/ysbaddaden/frost/issues/1#issuecomment-167912888
      end

      def controller_class
        controller.split('/').map(&.camelcase).join("::") + "Controller"
      end

      def regular_expression
        prepared = path
          .gsub(/\*[\w\d_]+/, "_SPLAT_")
          .gsub(/:[\w\d_]+/, "_PARAM_")
          .gsub(/\./, "_DOT_")
          .gsub(/\//, "_SLASH_")
          .gsub(/\(/, "_LPAREN_")
          .gsub(/\)/, "_RPAREN_")

        matcher = prepared
          .gsub(/_SPLAT_/, "(.*?)")
          .gsub(/_PARAM_/, "([^\\/]+?)")
          .gsub(/_DOT_/, "\\.")
          .gsub(/_SLASH_/, "\\/")
          .gsub(/_LPAREN_/, "(?:")
          .gsub(/_RPAREN_/, ")?")

         "/\\A#{ matcher }\\/?\\Z/"
      end

      def to_crystal_s(io : IO)
        params = path
          .scan(FIND_PARAM_NAME)
          .map { |match| match[1].inspect }

        io << "      when #{ regular_expression }\n"
        params.each_with_index do |name, index|
          io << "        params[#{ name }] = URI.unescape($#{ index + 1}) if $#{ index + 1 }?\n"
        end

        io << "        controller = #{ controller_class }.new(context, params, #{ action.inspect })\n"
        io << "        controller.run_action do\n"
        io << "          controller.#{ action }\n"
        io << "          controller.render unless controller.already_rendered?\n"
        io << "        end\n"
      end
    end
  end
end
