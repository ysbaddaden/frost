module Trail
  class Record
    # TODO: test customize foreign_key
    module Associations
      macro has_many(name, foreign_key = nil)
        {% name = name.id %}
        {% singular = run("../../support/inflector/singularize", name) %}
        {% model_name = singular.camelcase.id %}
        {% relation = @type.name.underscore.id %}
        {% foreign_key ||= "#{ relation }_id" %}

        def {{ name }}
          @{{ name }} ||= {{ model_name }}.where({ {{ foreign_key.id }}: id })
        end

        # TODO: deassociate current records (applying dependent customization)
        def {{ name }}=(records)
          records.each do |record|
            record.{{ relation }} = self
            record.save
          end
          @{{ name }} = records
        end

        # TODO: cast array elements to column type (eg: String?, Int32, ...)
        def {{ singular.id }}_ids
          {{ name }}.pluck({{ model_name }}.primary_key)
        end

        def {{ singular.id }}_ids=(ids)
          self.{{ name }} = {{ model_name }}.find(ids)
        end
      end
    end
  end
end
