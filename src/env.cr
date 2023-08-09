module Frost
  class_getter env = Env.new

  struct Env
    @name : String

    def initialize(name : String? = nil)
      @name =
        if name
          name
        else
          ENV.fetch("FROST_ENV", "development")
        end
    end

    def local? : Bool
      test? || development?
    end

    def development? : Bool
      @name == "development"
    end

    def production? : Bool
      @name == "production"
    end

    def test? : Bool
      @name == "test"
    end

    def name : String
      @name
    end

    # :nodoc:
    def to_s : String
      @name
    end

    # :nodoc:
    def to_s(io : IO) : Nil
      io << @name
    end

    macro method_missing(name)
      {% name = name.stringify %}

      {% if name.ends_with?('?') %}
        {{name}}[0...-1] == @name
      {% else %}
        {% raise "ERROR: no such method #{@type}\#{{name}}" %}
      {% end %}
    end
  end
end
