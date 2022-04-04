require "./support/safe_buffer"
require "./utils"
require "./view/helpers"

module Frost
  class Controller
    macro inherited
      struct ::{{ @type.name.gsub(/Controller$/, "View").id }} < ::Frost::View
        @controller : {{ @type.name.id }}
      end
    end
  end

  class MissingTemplateError < Exception
    def initialize(path, format, search_paths = Frost::View::SEARCH_PATHS)
      message = String.build do |str|
        str << "Missing template "
        path.inspect(str)
        str << " with format "
        format.inspect(str)
        str << " in "
        search_paths.inspect(str)
      end

      super message
    end
  end

  abstract struct View
    include Helpers

    SEARCH_PATHS = %w[./src/views]

    protected def __str__ : SafeBuffer
      @__str__
    end

    def initialize(@controller)
      @__str__ = SafeBuffer.new(@controller.response)
    end

    def layout(name, format = "html", &block) : Nil
      name, format = name.to_s, format.to_s

      {% begin %}
        {% for search_path in SEARCH_PATHS %}
          {% for template_path in `#{Frost::UTILS_BIN} ls '#{search_path.id}/layouts/*'`.strip.split("\n").sort %}
            {% unless template_path.empty? %}
              {% template_basename = template_path.split("/").last %}
              {% template_parts = template_basename.split(".") %}
              {% template_name = template_parts[0] %}
              {% template_engine = template_parts[-1] && template_parts[-1].downcase %}
              {% template_format = template_parts[-2] && template_parts[-2].downcase %}

              if name == {{template_name}} && format == {{template_format}}
                render_template {{template_path}}, {{template_engine}}
                return
              end
            {% end %}
          {% end %}
        {% end %}

        raise ::Frost::MissingTemplateError.new("layouts/#{name}", format)
      {% end %}
    end

    def self.template_exists?(name, format = "html") : Bool
      name, format = name.to_s, format.to_s

      {% begin %}
        {% view_path = @type.name.gsub(/View$/, "").gsub(/::/, "/").underscore.stringify %}

        {% for search_path in SEARCH_PATHS %}
          {% for template_path in `#{Frost::UTILS_BIN} ls '#{search_path.id}/#{view_path.id}/*'`.strip.split("\n").sort %}
            {% unless template_path.empty? %}
              {% template_basename = template_path.split("/").last %}
              {% template_parts = template_basename.split(".") %}
              {% template_name = template_parts[0] %}
              {% template_engine = template_parts[-1] && template_parts[-1].downcase %}
              {% template_format = template_parts[-2] && template_parts[-2].downcase %}

              if name == {{template_name}} && format == {{template_format}}
                return true
              end
            {% end %}
          {% end %}
        {% end %}

        false
      {% end %}
    end

    macro method_missing(call)
      def {{call.name}}(format = "html") : Nil
        format = format.to_s

        {% view_path = @type.name.gsub(/View$/, "").gsub(/::/, "/").underscore.stringify %}
        {% path = "#{view_path.id}/#{call.name}" %}

        {% for search_path in SEARCH_PATHS %}
          {% for template_path in `#{Frost::UTILS_BIN} ls '#{search_path.id}/#{path.id}.*'`.strip.split("\n").sort %}
            {% unless template_path.empty? %}
              {% template_basename = template_path.split("/").last %}
              {% template_parts = template_basename.split(".") %}
              {% template_engine = template_parts[-1] && template_parts[-1].downcase %}
              {% template_format = template_parts[-2] && template_parts[-2].downcase %}

              if format == {{template_format}}
                render_template {{template_path}}, {{template_engine}}
                return
              end
            {% end %}
          {% end %}
        {% end %}

        raise ::Frost::MissingTemplateError.new({{path}}, format)
      end
    end

    macro render_template(path, engine)
      {% if engine == "ecr" %}
        ::Frost::Utils.ecr({{path}}, "__str__")
      {% else %}
        {% raise "TODO: unsupported template engine for #{path}" %}
      {% end %}
    end

    def controller
      @controller
    end

    def context : HTTP::Server::Context
      @controller.context
    end

    def request : Frost::Request
      @controller.request
    end

    def response : HTTP::Server::Response
      @controller.response
    end

    def params : Frost::Routes::Params
      @controller.params
    end

    @controller_path : String?
    @controller_name : String?

    def controller_path : String
      @controller_path ||= @controller.class.name.gsub(/Controller$/, "").gsub("::", '/').underscore
    end

    def controller_name : String
      @controller_name ||=
        begin
          @controller.class.name =~ /([^:]+)Controller$/
          $1.underscore
        end
    end

    def action_name : String
      @controller.action_name
    end
  end
end
