module Trail
  module Routing
    # :nodoc:
    class Route
      FIND_PARAM_NAME = /[*:]([\w\d_]+)/

      property :path, :method, :controller, :action

      def initialize(@method, @path, @controller, @action, @route_name = nil)
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

      def route_name
        if route_name = @route_name
          route_name as String
        end
      end

      def to_crystal_s
        params = path
          .scan(FIND_PARAM_NAME)
          .map { |match| match[1].inspect }

        String.build do |str|
          str << "      when #{ regular_expression }\n"
          params.each_with_index do |name, index|
            str << "        params[#{ name }] = CGI.unescape($#{ index + 1}) if $#{ index + 1 }?\n"
          end
         #str << "        params[\"controller\"] = #{ controller.inspect }\n"
         #str << "        params[\"action\"] = #{ action.inspect }\n"

          str << "        controller = #{ controller_class }.new(request, params, #{ action.inspect })\n"
          str << "        controller.run_action do\n"
          str << "          controller.#{ action }\n"
          str << "          controller.render unless controller.already_rendered?\n"
          str << "        end\n"

         #str << "        if controller.responds_to?(:#{ action }_with_filters)\n"
         #str << "          controller.#{ action }_with_filters\n"
         #str << "        else\n"
         #str << "          controller.#{ action }\n"
         #str << "        end\n"
        end
      end
    end
  end
end
