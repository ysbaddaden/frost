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

    private def __render(io : IO, &) : Nil
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
      raise ArgumentError.new("No IO to render to: you must call #{self.class.name}#render(io : IO)") unless @__io_valid__

      view.render(@__io__, &block)
    end

    def template : Nil
      {% raise "ERROR: you must define #{@type.name}#template" %}
    end

    def template(&block) : Nil
      {% raise "ERROR: you must define #{@type.name}#template(&block)" %}
    end

    # Returns the content type to use in the response.
    def content_type : String
      "text/plain; charset=utf-8"
    end
  end
end

require "./view/*"
