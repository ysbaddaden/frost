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

    def development?
      @name == "development"
    end

    def production?
      @name == "production"
    end

    def test?
      @name == "test"
    end

    def name
      @name
    end

    def to_s
      @name
    end

    def to_s(io : IO)
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
