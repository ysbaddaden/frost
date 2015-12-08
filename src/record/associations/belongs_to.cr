module Trail
  class Record
    module Associations
      macro belongs_to(name, foreign_key = nil, dependent = nil, autosave = true)
        {% name = name.id %}
        {% model_name = name.stringify.camelcase.id %}
        {% foreign_key = (foreign_key || "#{ name }_id").id %}

        {% ASSOCIATIONS[name.symbolize] = :belongs_to %}

        def {{ name }}(reload = false)
          @{{ name }} = nil if reload
          @{{ name }} ||= begin
            raise RecordNotFound.new if {{ foreign_key }}.nil?
            {{ model_name }}.find({{ foreign_key }})
          end
        end

        def {{ name }}?(reload = false)
          @{{ name }} = nil if reload
          @{{ name }} ||= begin
            return nil if {{ foreign_key }}.nil?
            {{ model_name }}.find_by?({ {{ model_name }}.primary_key => {{ foreign_key }} })
          end
        end

        def {{ name }}=(record : {{ model_name }})
          if id = record.id
            self.{{ foreign_key }} = id
          else
            @{{ foreign_key }} = nil
          end
          @{{ name }} = record
        end

        def {{ name }}=(record : Nil)
          # TODO: don't generate if column can't be null
          @{{ name }} = self.{{ foreign_key }} = nil
        end

        def build_{{ name }}(attributes)
          # FIXME: what if relation already exists?
          self.{{ name }} = {{ model_name }}.build(attributes)
        end

        def create_{{ name }}(attributes)
          # FIXME: what if relation already exists?
          record = build_{{ name }}(attributes)
          record.save
          record
        end

        def create_{{ name }}!(attributes)
          # FIXME: what if relation already exists?
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

          protected def handle_before_save_{{ name }}_dependency
            if {{ name }} = @{{ name }}
              return if {{ name }}._saving?

              if {{ name }}.save
                self.{{ foreign_key }} = {{ name }}.id.not_nil!
              end
            end
          end
        {% end %}

        {% if dependent == :destroy || dependent == :delete %}
          protected def handle_delete_{{ name }}_dependency
            if relation = self.{{ name }}?
              relation.{{ dependent.id }}
            end
            nil
          end
        {% end %}
      end
    end
  end
end
