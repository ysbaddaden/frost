module Frost
  abstract struct View
    @__io__ = uninitialized IO
    @__io_valid__ = false

    def render(io : IO) : Nil
      __render(io) { template }
    end

    def render(io : IO, &block) : Nil
      __render(io) { template(&block) }
    end

    @[AlwaysInline]
    protected def __render(io : IO, &) : Nil
      original_io, @__io__ = @__io__, io
      original_valid, @__io_valid__ = @__io_valid__, true
      begin
        yield
      ensure
        @__io__ = original_io
        @__io_valid__ = original_valid
      end
    end

    def render(view : View, &block) : Nil
      if @__io_valid__
        view.render(@__io__, &block)
      else
        raise ArgumentError.new("No IO to render to: you must call #{self.class.name}#render(io : IO)")
      end
    end

    def render(view : View) : Nil
      if @__io_valid__
        view.render(@__io__)
      else
        raise ArgumentError.new("No IO to render to: you must call #{self.class.name}#render(io : IO)")
      end
    end

    def template : Nil
      {% raise "ERROR: you must define #{@type.name}#template" %}
    end

    def template(&) : Nil
      {% raise "ERROR: you must define #{@type.name}#template(&)" %}
    end

    # Returns the content type to use in the response.
    def content_type : String
      "text/plain; charset=utf-8"
    end
  end
end

require "./view/*"
