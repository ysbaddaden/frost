module Frost
  abstract class View
    class FormBuilder
      getter :resource, :context

      def initialize(@resource : Frost::Record, @context)
      end

      def render(method, multipart, enforce_utf8, attributes)
        form_tag(url, method, multipart, enforce_utf8, attributes) do
          with self yield
        end
      end

      {% for type in %w(color date datetime datetime_local email hidden month number password range search telephone phone time url week) %}
        def {{ type.id }}_field(name, attributes = nil)
          attrs = to_typed_attributes_hash(attributes)
          attrs[:id] = input_id_for(name)
          context.{{ type.id }}_field_tag(input_name_for(name), resource[name], attributes)
        end
      {% end %}

      def button(content : String, attributes = nil)
        context.button_tag(content, attributes)
      end

      def button(attributes = nil)
        context.button_tag(attributes) { yield }
      end

      def check_box(name, value, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:id] = input_id_for(name)
        attrs[:checked] = resource[name] == value
        context.check_box_tag(input_name_for(name), value, attributes)
      end

      def file_field(name, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:id] = input_id_for(name)
        context.file_field_tag(input_name_for(name), attributes)
      end

      def label(name, content : String, attributes = nil)
        context.label_tag(input_name_for(name), content, attributes)
      end

      def label(name, attributes = nil)
        context.label_tag(input_name_for(name), attributes)
      end

      def label(name, attributes = nil)
        context.label_tag(input_name_for(name), attributes) { yield }
      end

      def radio_button(name, options, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:id] = input_id_for(name)
        attrs[:selected] = resource[name] == value
        context.radio_button_tag(input_name_for(name), options, attributes)
      end

      def select(name, options, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:id] = input_id_for(name)
        context.select_tag(input_name_for(name), options, attributes)
      end

      def submit(value = nil, name = "commit", attributes = nil)
        value ||= if resource.persisted?
                    "Update #{ resource.name.titleize }"
                  else
                    "Create #{ resource.name.titleize }"
                  end
        context.submit_tag(value, name, attributes)
      end

      def text_area(name, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:id] = input_id_for(name)
        context.text_area_tag(input_name_for(name), resource[name], attributes)
      end

      private def url
        url = resource.class.name.pluralize.underscore
        url += "/" + resource.to_param if resource.persisted?
        url
      end

      private def input_value_for(name)
        if resource.is_a?(Frost::Record)
          resource[name]
        end
      end

      private def input_name_for(name)
        "#{ prefix }[#{ name }]"
      end

      private def input_id_for(name)
        "#{ prefix }_#{ name }"
      end

      private def prefix
        @prefix ||= resource.class.name.underscore
      end
    end

    module FormHelper
      def form_for(resource, method = "post", multipart = false, enforce_utf8 = true, attributes = nil)
        FormBuilder.new(resource).render(method, multipart, enforce_utf8, attributes) do
          yield
        end
      end
    end
  end
end
