abstract class Frost::Current
  macro inherited
    class ::Fiber
      @__frost_storage : {{@type.name.id}}?

      def __frost_storage : {{@type.name.id}}
        @__frost_storage ||= {{@type.name.id}}.new
      end
    end
  end

  macro attribute(decl)
    {% raise "Frost::Current#attribute expects a TypeDeclaration" unless decl.is_a?(TypeDeclaration) %}
    {% raise "Frost::Current#attribute discards default values" if decl.value %}

    @{{decl.var}} : {{decl.type}} | Nil

    def self.{{decl.var}} : {{decl.type}}
      instance.{{decl.var}}
    end

    def {{decl.var}} : {{decl.type}}
      @{{decl.var}}.not_nil!
    end

    def self.{{decl.var}}? : {{decl.type}} | Nil
      instance.{{decl.var}}?
    end

    def {{decl.var}}? : {{decl.type}} | Nil
      @{{decl.var}}
    end

    def self.{{decl.var}}=({{decl.var}} : {{decl.type}} | Nil) : {{decl.type}} | Nil
      instance.{{decl.var}} = {{decl.var}}
    end

    def {{decl.var}}=(@{{decl.var}} : {{decl.type}} | Nil) : {{decl.type}} | Nil
    end
  end

  def self.reset! : Nil
    instance.reset!
  end

  def reset! : Nil
    {% for ivar in @type.instance_vars %}
      @{{ivar.id}} = nil
    {% end %}
  end

  private def self.instance : Current
    Fiber.current.__frost_storage
  end
end
