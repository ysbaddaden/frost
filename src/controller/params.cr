require "http/params"

module Frost
  class Controller
    alias ParamType = String | Array(ParamType) | Hash(String, ParamType)

    module Params
      #class Error < Exception
      #end

      #class UnexpectedParamError < Error
      #end

      # Parses an application/x-www-form-urlencoded string then sets properties
      # on the object with casted values.
      #
      # ```
      # def employee_params(employee)
      #   Params.mapping(employee, {
      #     name: String,
      #     email: String,
      #     salary: Int32,
      #   })
      # end
      #
      # # new employee:
      # employee = employee_params(Employee.new)
      # employee.save
      #
      # # update an existing employee:
      # employee = employee_params(Employee.find(1))
      # employee.save
      # ```
      #
      # Unknown properties will be skipped, unless `strict` is true, in which
      # case an `UnexpectedParamError` will be raised.
      #macro mapping(object, properties, strict = false)
      #  # TODO: walk and cast nested properties:
      #  #
      #  #       [String] => expect an Array of strings
      #  #       [Int] => expect an Array of integers
      #  #       "{ name: String }" => expect a Hash with a property name (String)
      #  #       "{ name: [String] }" => expect a Hash with a property name ([] of String)
      #  #       "[{ name: String }]" => expect an Array of Hash with a property name ([] of String)
      #  #       "[{ name: [String] }]" => expect an Array of Hash with a property name ([] of String)
      #  #       "[{ name: [{ name: String }] }]" => expect an Array of Hash with a property name ([] of String)
      #  body_params.each do |key, value|
      #    case key
      #    {% for name, type in properties %}
      #    when {{ name.stringify }}
      #      {{ object.id }}.{{ name.id }} = value as {{ type.id }}
      #    {% end %}
      #    else
      #      raise UnexpectedParamError.new("unexpected param #{ key }") if strict
      #    end
      #  end

      #  {{ object.id }}
      #end

      # Parses an application/x-www-form-urlencoded string as a
      # `Hash(String, ParamType)` object.
      def self.parse(string, params = {} of String => ParamType)
        return params unless string

        HTTP::Params.parse(string) do |key, value|
          subkeys = key.scan(/\[(.*?)\]/).map { |m| m[1] }

          # shortcut: don't search for nested data
          if subkeys.empty?
            params[key] = value
            next
          end

          # looking for inner data (eg: x[y][z])
          name = key[0 ... key.index("[").not_nil!]
          subkeys.unshift(name)

          hsh = params
          last = subkeys.pop unless subkeys.last == ""

          # TODO: there must be simpler way to fetch inner data
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

        params
      end
    end
  end
end
