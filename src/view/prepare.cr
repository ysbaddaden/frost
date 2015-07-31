module Trail
  class View
    # :nodoc:
    class PrepareViews
      def initialize(@views_path, controller_name)
        @controller_path = controller_name
          .gsub(/View\Z/, "")
          .split("::")
          .map(&.underscore)
          .join('/')
        @actions = {} of String => Array(String)
      end

      def views_path
        File.join(@views_path, @controller_path)
      end

      # TODO: recursively search directories (?)
      def find_templates
        len = (views_path.size + 1) .. -1

        Dir[File.join(views_path, "*.ecr")].each do |path|
          if path[len] =~ /\A(.+)\.(.+?)\.ecr\Z/
            yield path, $1, $2
          end
        end
      end

      def embed_template(path, action_name, format, str)
        @actions[format] ||= [] of String
        @actions[format] << action_name

        str << "def #{ to_method_name(action_name, format) }\n"
        str << "  String.build do |__str__|\n"
        str << "    embed_ecr #{ path.inspect }, \"__str__\"\n"
        str << "  end\n"
        str << "end\n\n"
      end

      def dispatch_renders(str)
        str << "def render(action, format = DEFAULT_FORMAT)\n"

        if @actions.size > 0
          str << "  case format\n"

          @actions.each do |format, action_names|
            str << "  when #{ format.inspect }\n"
            str << "    case action\n"

            action_names.each do |action_name|
              str << "    when #{ action_name.inspect }\n"
              str << "      return #{ to_method_name(action_name, format) }\n"
            end
            str << "    end\n"
          end
          str << "  end\n\n"
        end

        str << "  raise Trail::View::MissingTemplate.new(#{ views_path.inspect }, action, format)\n"
        str << "end\n\n"
      end

      private def to_method_name(action, format)
        "render_#{ action.gsub('/', '_') }_#{ format }"
      end

      def to_crystal_s
        String.build do |str|
          find_templates do |path, action, format|
            embed_template(path, action, format, str)
          end
          dispatch_renders(str)
        end
      end
    end

    at_exit do
      puts PrepareViews.new(ARGV[0], ARGV[1]).to_crystal_s
    end
  end
end
