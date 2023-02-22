module Frost
  abstract struct DOM < View
    PREFERS_CLOSED_ELEMENTS = false

    # Escapes a single XML or HTML `Char`.
    def escape(char : Char) : Char | String
      # https://stackoverflow.com/questions/1091945/what-characters-do-i-need-to-escape-in-xml-documents
      case char
      when '&' then "&amp;"
      when '<' then "&lt;"
      when '>' then "&gt;"
      when '"' then "&quot;"
      when '\'' then "&apos;"
      else char
      end
    end

    # Escapes a single XML or HTML `Char` to the given IO.
    def escape(io : IO, char : Char) : Nil
      io << escape(char)
    end

    # Escapes XML or HTML characters for any object (casted to String).
    def escape(io : IO, obj) : Nil
      obj.to_s.each_char { |char| io << escape(char) }
    end

    # Registers a DOM Element.
    macro register_element(tag_name)
      @[AlwaysInline]
      def {{tag_name.id}}(contents = nil, **attributes) : Nil
        if contents.nil? && PREFERS_CLOSED_ELEMENTS
          @__io__ << "<{{tag_name.id}}"
          render_attributes(attributes) unless attributes.empty?
          @__io__ << '/' << '>'
        else
          self.{{tag_name.id}}(**attributes) { contents }
        end
      end

      @[AlwaysInline]
      def {{tag_name.id}}(**attributes, &block) : Nil
        @__io__ << "<{{tag_name.id}}"
        render_attributes(attributes) unless attributes.empty?
        @__io__ << '>'

        if contents = (with self yield)
          concat(contents)
        end

        @__io__ << "</{{tag_name.id}}>"
      end
    end

    # Registers a void DOM Element (i.e. no content).
    macro register_void_element(tag_name)
      @[AlwaysInline]
      def {{tag_name.id}}(**attributes) : Nil
        @__io__ << "<{{tag_name.id}}"
        render_attributes(attributes) unless attributes.empty?
        @__io__ << '/' << '>'
      end
    end

    private def render_attributes(attributes, prefix = nil) : Nil
      attributes.each do |attr_name, attr_value|
        if attr_value.is_a?(NamedTuple)
          if prefix
            render_attributes(attr_value, "#{prefix}-#{attr_name}")
          else
            render_attributes(attr_value, prefix: attr_name)
          end
        else
          render_attribute_name(attr_name, prefix)
          render_attribute_value(attr_value)
        end
      end
    end

    # NOTE: since we expect attributes to be a NamedTuple with symbol keys and
    #       not a hash that could be unsafe data, maybe we don't need to escape
    #       the attribute name?
    private def render_attribute_name(attr_name, prefix = nil) : Nil
      @__io__ << ' '
      if prefix
        escape(@__io__, prefix)
        @__io__ << '-'
      end
      escape(@__io__, attr_name)
    end

    private def render_attribute_value(attr_value : Enumerable) : Nil
      @__io__ << '=' << '"'
      attr_value.each_with_index do |value, index|
        @__io__ << ' ' unless index == 0
        escape(@__io__, value)
      end
      @__io__ << '"'
    end

    private def render_attribute_value(attr_value) : Nil
      @__io__ << '=' << '"'
      escape(@__io__, attr_value)
      @__io__ << '"'
    end

    private def render_attribute_value(attr_value : Bool) : Nil
      @__io__ << %(="false") unless attr_value
    end

    # Casts `contents` to a String then escapes and appends it to the output.
    @[AlwaysInline]
    def concat(contents) : Nil
      escape(@__io__, contents)
    end

    @[AlwaysInline]
    def concat(contents : Nil) : Nil
    end

    # ibid
    # @[AlwaysInline]
    # def concat(contents : Number) : Nil
    #   @__io__ << contents
    # end

    # Directly appends `contents` to the output, without any escaping. Never use
    # it to output data from unknown origin, otherwise you may open a website to
    # different attacks (e.g. cross-site-scripting aka XSS).
    @[AlwaysInline]
    def unsafe_raw(contents : String) : Nil
      @__io__ << contents
    end

    # Outputs a comment. Remember that `--` (double hyphen) is forbidden within
    # comments.
    @[AlwaysInline]
    def comment(contents) : Nil
      @__io__ << "<!--" << contents << "-->"
    end

    # Outputs a whitespace character. Elements are always outputted directly but
    # sometimes we'd like to have a whitespace between them.
    @[AlwaysInline]
    def whitespace : Nil
      @__io__ << ' '
    end

    # Same as `#whitespace` but outputs a whitespace before and after the block.
    @[AlwaysInline]
    def whitespace(&) : Nil
      whitespace
      yield
      whitespace
    end
  end
end
