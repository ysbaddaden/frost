require "html"

module Frost
  abstract class View
    module TagHelper
      alias AttributeValue = String | Int32 | Float32 | Int64 | Float64 | Bool | Nil | Array(String?) | Array(String)

      # Formats a HTML tag whose contents is a block.
      # ```
      # content_tag(:div) { "data" }  # => <div>data</div>
      # content_tag(:div, { id: "anchor" }) { tag :br }  # => <div id="anchor"><br/></div>
      # ```
      def content_tag(name, attributes = nil)
        content_tag(name, capture { yield }, attributes)
      end

      # Formats a HTML tag.
      # ```
      # content_tag :div  # => <div></div>
      # content_tag :div, data  # => <div>data</div>
      # ```
      def content_tag(name, contents = nil, attributes = nil)
        String.build do |io|
          io << "<" << name.to_s
          format_attributes(attributes, io)
          io << ">"
          io << contents
          io << "</" << name << ">"
        end
      end

      # Formats a self closed HTML tag.
      # ```
      # tag :br  # => <br/>
      # tag :hr, { class: "pretty" }  # => <hr class="pretty"/>
      # tag :hr, { class: "pretty" }  # => <hr class="pretty"/>
      # ```
      #
      # You may also want the tag to not be closed:
      # ```
      # tag :form, open: true  # => <form>
      # tag :form, { class: "inline" }, open: true  # => <form class=inline">
      # ```
      def tag(name, attributes = nil, open = false)
        String.build do |io|
          io << "<" << name.to_s
          format_attributes(attributes, io)
          io << (open ? ">" : "/>")
        end
      end

      # TODO: datasets (eg: { data: { user_id: 1 } } => data-user-id="1")
      protected def format_attributes(attributes, io : IO)
        return unless attributes

        attributes.keys.sort.each do |key|
          attr_name = key.to_s.dasherize

          case value = attributes[key]
          when Bool
            io << " " << attr_name if value

          when Array
            io << " " << attr_name << "=\""
            HTML.escape(value.join(" "), io)
            io << "\""

          else
            io << " " << attr_name << "=\""
            HTML.escape(value.to_s, io)
            io << "\""
          end
        end
      end

      protected def to_typed_attributes_hash(attributes)
        if attributes.is_a?(Hash(Symbol, AttributeValue))
          return attributes
        end

        attrs = {} of Symbol => AttributeValue
        if attributes
          attrs.merge!(attributes)
        end
        attrs
      end
    end
  end
end
