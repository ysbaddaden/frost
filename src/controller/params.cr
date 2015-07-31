require "cgi"

module Trail
  class Controller
    alias ParamType = String | Array(ParamType) | Hash(String, ParamType)

    class Params < Hash(String, ParamType)
      # Parses the Query String and the Body of a HTTP::Request object.
      def parse(request)
        parse_urlencoded(request.uri.query)
        parse_body(request)
      end

      def parse_body(request)
        case request.headers["Content-Type"]?
        when "application/x-www-form-urlencoded" then parse_urlencoded(request.body)
        when "multipart/form-data"               then # TODO: parse multipart body
        when "application/json"                  then # TODO: parse JSON body
        when "application/xml", "text/xml"       then # TODO: parse XML body (?)
        end
      end

      def parse_urlencoded(query)
        return self unless query

        CGI.parse(query) do |key, value|
          subkeys = key.scan(/\[(.*?)\]/).map { |m| m[1] }

          if subkeys.empty?
            self[key] = value
            next
          end

          name = key[0 ... key.index("[").not_nil!]
          subkeys.unshift(name)

          hsh = self
          last = subkeys.pop unless subkeys.last == ""

          subkeys.each_with_index do |subkey, index|
            next if subkey == ""

            hsh = if subkeys[index + 1]? == ""
                    if hsh.is_a?(Hash(String, ParamType))
                      if !hsh[subkey]? || !hsh[subkey].is_a?(Array(ParamType))
                        hsh[subkey] = [] of ParamType
                      end
                      hsh[subkey]
                    elsif hsh.is_a?(Array(ParamType))
                      sub = [] of ParamType
                      hsh << sub
                      sub
                    else
                      # unreachable (?)
                      raise "Invalid type #{ hsh.class.name } for param #{ key }, expected Array or Hash"
                    end
                  else
                    if hsh.is_a?(Hash(String, ParamType))
                      if !hsh[subkey]? || !hsh[subkey].is_a?(Hash(String, ParamType))
                        hsh[subkey] = {} of String => ParamType
                      end
                      hsh[subkey]
                    elsif hsh.is_a?(Array(ParamType))
                      sub = {} of String => ParamType
                      hsh << sub
                      sub
                    else
                      # unreachable (?)
                      raise "Invalid type #{ hsh.class.name } for param #{ key }, expected Array or Hash"
                    end
                  end
          end

          case hsh
          when Hash(String, ParamType)
            hsh[last.to_s] = value
          when Array(ParamType)
            if last
              sub = {} of String => ParamType
              sub[last] = value
              hsh << sub
            else
              hsh << value
            end
          else
            # unreachable (?)
            raise "Error while parsing urlencoded params: unexpected #{ hsh.class.name }, expected Array or Hash"
          end
        end

        self
      end
    end
  end
end
