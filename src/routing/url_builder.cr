module Frost
  module Routing
    # :nodoc:
    class UrlBuilder
      OPTIONAL_RE = /(\(.+?\))/
      PARAM_NAME_RE = /([*:][\w\d_]+)/
      URL_PARAMS = %w(protocol host)

      getter required_params
      getter optional_params
      @path : String
      @parsed_path : String

      def initialize(@path)
        @required_params = [] of String
        @optional_params = [] of String
        @parsed_path = parse
      end

      def to_args(url = false)
        optional_params = url ? self.optional_params + URL_PARAMS : self.optional_params
        optional_params = optional_params.map { |param_name| "#{ param_name } = nil" }
        (required_params + optional_params).join(", ")
      end

      def to_path
        "\"#{ @parsed_path }\"\n"
      end

      def to_url
        String.build do |str|
          URL_PARAMS.each do |arg|
            str << "    #{ arg } ||= url_options[:#{ arg }]\n"
          end
          str << "    "
          str << "\"\#{ protocol }://\#{ host }" << @parsed_path << "\""
        end
      end

      private def parse
        replace_params(replace_optionals(@path)).first
      end

      private def replace_optionals(str)
        str.gsub(OPTIONAL_RE) do |optional|
          segment, params = replace_params(optional[1 ... -1], optional: true)

          String.build do |str|
            str << "\#{ \"#{ segment }\" if #{ params.join("&&") } }"
          end
        end
      end

      private def replace_params(str, optional = false)
        params = [] of String

        segment = str.gsub(PARAM_NAME_RE) do |match|
          param_name = match[1 .. -1]
          if optional
            optional_params << param_name
          else
            required_params << param_name
          end
          params << param_name
          "\#{ #{ param_name } }"
        end

        {segment, params}
      end
    end
  end
end
