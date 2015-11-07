module Trail
  class Record
    # TODO: test customize foreign_key
    module Associations
      macro has_one(name, foreign_key = nil)
        {% name = name.id %}
        {% model_name = name.stringify.camelcase.id %}
        {% foreign_key ||= "#{ name }_id" %}

        def {{ name }}
          {{ model_name }}.where({ {{ foreign_key.id }}: id }).first
        end

        def {{ name }}=(record : {{ model_name }})
          record.{{ foreign_key.id }} = id
          record.save
        end

        def build_{{ name }}(attributes)
          {{ model_name }}.build(attributes)
        end

        def create_{{ name }}(attributes)
          record = {{ model_name }}.build(attributes)
          record.{{ foreign_key.id }} = id
          record.save
          record
        end
      end
    end
  end
end
