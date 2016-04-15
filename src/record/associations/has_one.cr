module Frost
  abstract class Record
    module Associations
      macro has_one(name, foreign_key = nil, dependent = nil, inverse_of = nil, autosave = true)
        {% name = name.id %}
        {% relation = @type.name.split("::").last.underscore.id %}
        {% model_name = name.stringify.camelcase.id %}
        {% foreign_key = (foreign_key || "#{ relation }_id").id %}

        {% ASSOCIATIONS[name.symbolize] = :has_one %}

        @{{ name }} : {{ model_name }}?

        def {{ name }}(reload = false)
          @{{ name }} = nil if reload
          @{{ name }} ||= {{ model_name }}.find_by({ {{ foreign_key }}: id })
        end

        def {{ name }}?(reload = false)
          @{{ name }} = nil if reload
          @{{ name }} ||= {{ model_name }}.find_by?({ {{ foreign_key }}: id })
        end

        def {{ name }}=(record : {{ model_name }})
          if id = self.id
            transaction do
              {{ model_name }}.where({ {{ foreign_key }}: id }).delete_all
              record.{{ foreign_key }} = id
              record.save
            end
          end
          {% if inverse_of %}
            record.{{ inverse_of.id }} = self
          {% end %}
          @{{ name }} = record
        end

        def {{ name }}=(record : Nil)
          # TODO: don't generate if column can't be null
          transaction do
            {{ model_name }}.where({ {{ foreign_key }}: id }).delete_all if id
            @{{ name }} = nil
          end
        end

        def build_{{ name }}(attributes)
          record = {{ model_name }}.build(attributes)
          if id = self.id
            record.{{ foreign_key }} = id
          end
          {% if inverse_of %}
            record.{{ inverse_of.id }} = self
          {% end %}
          @{{ name }} = record
        end

        def create_{{ name }}(attributes)
          record = build_{{ name }}(attributes)
          record.save
          record
        end

        def create_{{ name }}!(attributes)
          record = build_{{ name }}(attributes)
          record.save!
          record
        end

        {% if autosave %}
          protected def handle_validate_{{ name }}_dependency
            if {{ name }} = @{{ name }}
              return if {{ name }}._validating?
              errors.add(:base, "{{ name }} is invalid") unless {{ name }}.valid?
            end
          end

          protected def handle_after_save_{{ name }}_dependency
            if {{ name }} = @{{ name }}
              return if {{ name }}._saving?
              {{ name }}.{{ foreign_key }} = id.not_nil!
              {{ name }}.save
            end
          end
        {% end %}

        {% if dependent %}
          protected def handle_delete_{{ name }}_dependency
            {% if dependent == :destroy || dependent == :delete %}
              if relation = self.{{ name }}?
                relation.{{ dependent.id }}
              end
            {% elsif dependent == :nullify %}
              {{ model_name }}.where({ {{ foreign_key }}: id }).update_all({ {{ foreign_key }}: nil })
            {% elsif dependent == :exception %}
              raise DeleteRestrictionError.new if {{ model_name }}.where({ {{ foreign_key }}: id }).any?
            {% end %}
            nil
          end
        {% end %}
      end
    end
  end
end
