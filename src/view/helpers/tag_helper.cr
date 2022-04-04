abstract struct Frost::View
  module Helpers::TagHelper
    def tag(tag_name : String | Symbol, **attributes) : SafeString
      with_output_buffer do
        __str__ << '<' << html_escape(tag_name)
        tag_attributes attributes unless attributes.empty?
        __str__ << '/' << '>'
      end.html_safe
    end

    def content_tag(tag_name : String | Symbol, contents = nil, **attributes) : SafeString
      content_tag(tag_name, **attributes) do
        concat contents if contents
      end
    end

    def content_tag(tag_name : String | Symbol, **attributes, &block) : SafeString
      escaped_name = html_escape(tag_name)

      with_output_buffer do
        __str__ << '<' << escaped_name
        tag_attributes attributes unless attributes.empty?
        __str__ << '>'
        __str__ << with_output_buffer { yield }
        __str__ << '<' << '/' << escaped_name << '>'
      end.html_safe
    end

    private def tag_attributes(attributes, prefix = nil) : Nil
      attributes.each do |attr_name, attr_value|
        if attr_value.is_a?(NamedTuple)
          if prefix
            tag_attributes attr_value, "#{prefix}-#{attr_name}"
          else
            tag_attributes attr_value, attr_name
          end
        else
          # NOTE: since we expect attributes to be a NamedTuple with symbol keys
          #       and not a hash that could be unsafe data, maybe we don't need
          #       to escape the attribute name?
          __str__ << ' '
          __str__ << html_escape(prefix) << '-' if prefix
          __str__ << html_escape(attr_name)

          case attr_value
          when true
            # skip value to avoid repeating name="name")
          when Enumerable
            __str__ << '=' << '"'
            attr_value.each_with_index do |value, index|
              __str__ << ' ' unless index == 0
              __str__ << html_escape(value)
            end
            __str__ << '"'
          else
            __str__ << '=' << '"' << html_escape(attr_value) << '"'
          end
        end
      end
    end
  end
end
