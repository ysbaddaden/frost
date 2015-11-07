module Trail
  class Record
    # TODO: test customize foreign_key
    module Associations
      macro belongs_to(name, foreign_key = nil)
        {% name = name.id %}
        {% model_name = name.stringify.camelcase.id %}
        {% foreign_key ||= "#{ name }_id" %}

        def {{ name }}(reload = false)
          @{{ name }} = nil if reload
          @{{ name }} ||= begin
            if {{ foreign_key.id }}.nil?
              raise RecordNotFound.new
            else
              {{ model_name }}.find({{ foreign_key.id }})
            end
          end
        end

        def {{ name }}=(record : {{ model_name }})
          if id = record.id
            self.{{ foreign_key.id }} = id
          else
            @{{ foreign_key.id }} = nil
          end
          @{{ name }} = record
        end

        # FIXME: don't generate if column can't be null
        def {{ name }}=(record : Nil)
          @{{ name }} = self.{{ foreign_key.id }} = nil
        end

        def build_{{ name }}(attributes)
          self.{{ name }} = {{ model_name }}.build(attributes)
        end

        def create_{{ name }}(attributes)
          self.{{ name }} = {{ model_name }}.create(attributes)
        end
      end
    end
  end
end
