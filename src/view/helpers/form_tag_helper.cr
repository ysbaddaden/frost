module Frost
  class View
    module FormTagHelper
      def form_tag(url, method = "post", multipart = false, enforce_utf8 = true, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        method = method.to_s

        attrs[:method] = (method == "post" || method == "get") ? method : "post"
        attrs[:action] = url.to_s
        attrs[:enctype] = "multipart/form-data" if multipart

        content_tag(:form, attrs) do
          String.build do |io|
            io << hidden_field_tag(:_method, method) unless attrs[:method] == method
            io << utf8_enforcer_tag if enforce_utf8
            io << capture { yield }
          end
        end
      end

      def button_tag(content : String, attributes = nil)
        content_tag(:button, content, attributes)
      end

      def button_tag(attributes = nil)
        button_tag(capture { yield }, attributes)
      end

      def check_box_tag(name, value = "1", attributes = nil)
        input_tag(:check_box, name, value, attributes)
      end

      def color_field_tag(name, value = nil, attributes = nil)
        input_tag(:color, name, value, attributes)
      end

      def date_field_tag(name, value = nil, attributes = nil)
        if value.is_a?(Number)
          value = Time.at(value)
        end
        input_tag(:date, name, value, attributes)
      end

      def datetime_field_tag(name, value = nil, attributes = nil)
        if value.is_a?(Number)
          value = Time.at(value)
        end
        input_tag(:datetime, name, value, attributes)
      end

      def datetime_local_field_tag(name, value = nil, attributes = nil)
        if value.is_a?(Number)
          value = Time.at(value)
        end
        input_tag("datetime-local", name, value, attributes)
      end

      def email_field_tag(name, value = nil, attributes = nil)
        input_tag(:email, name, value, attributes)
      end

      def file_field_tag(name, attributes = nil)
        input_tag(:file, name, nil, attributes)
      end

      def hidden_field_tag(name, value = nil, attributes = nil)
        input_tag(:hidden, name, value, attributes)
      end

      def label_tag(name, content : String, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:for] ||= name.to_s
        content_tag(:label, content, attrs)
      end

      def label_tag(name, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:for] ||= name.to_s
        content_tag(:label, name.titleize, attrs)
      end

      def label_tag(name, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:for] ||= name.to_s
        content_tag(:label, capture { yield }, attrs)
      end

      def month_field_tag(name, value = nil, attributes = nil)
        input_tag(:month, name, value, attributes)
      end

      def number_field_tag(name, value = nil, attributes = nil)
        input_tag(:number, name, value, attributes)
      end

      def password_field_tag(name, value = nil, attributes = nil)
        input_tag(:password, name, value, attributes)
      end

      def radio_button_tag(name, value = nil, attributes = nil)
        input_tag(:radio, name, value, attributes)
      end

      def range_field_tag(name, value = nil, attributes = nil)
        input_tag(:range, name, value, attributes)
      end

      def search_field_tag(name, value = nil, attributes = nil)
        input_tag(:search, name, value, attributes)
      end

      def select_tag(name, options : String, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:name] = name.to_s
        content_tag(:select, options, attrs)
      end

      def select_tag(name, attributes = nil)
        select_tag(name, capture { yield }, attributes)
      end

      def submit_tag(value = "Save changes", name = "commit", attributes = nil)
        input_tag(:submit, name, value, attributes)
      end

      def telephone_field_tag(name, value = nil, attributes = nil)
        input_tag(:tel, name, value, attributes)
      end

      # Alias for `#telephone_field_tag`
      def phone_field_tag(name, value = nil, attributes = nil)
        telephone_field_tag(name, value, attributes)
      end

      def text_area_tag(name, content = nil, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:name] = name.to_s
        content_tag(:textarea, content, attrs)
      end

      def text_field_tag(name, value = nil, attributes = nil)
        input_tag(:text, name, value, attributes)
      end

      def time_field_tag(name, value = nil, attributes = nil)
        if value.is_a?(Number)
          value = Time.epoch(value)
        end
        if value.is_a?(Time)
          value = value.to_s("%T")
        end
        input_tag(:time, name, value, attributes)
      end

      def url_field_tag(name, value = nil, attributes = nil)
        input_tag(:url, name, value, attributes)
      end

      def utf8_enforcer_tag
        "<input name=\"utf8\" type=\"hidden\" value=\"&#x2713;\"/>"
      end

      def week_field_tag(name, value = nil, attributes = nil)
        input_tag(:week, name, value, attributes)
      end

      private def input_tag(type, name, value = nil, attributes = nil)
        attrs = to_typed_attributes_hash(attributes)
        attrs[:type] = type.to_s
        attrs[:name] = name.to_s

        if value.is_a?(Time)
          attrs[:value] = value.iso8601
        elsif value
          attrs[:value] = value.to_s
        end

        tag(:input, attrs)
      end
    end
  end
end
