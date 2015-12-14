require "../finders"

module Frost
  class Record
    module Associations
      class HasManyCollection(T) < Query::Executor(T)
        # TODO: generate specific collection classes in has_many macro (+ yield
        #       macro block to add methods to the generated class)

        def initialize(@relation, @foreign_key, @dependent)
          super T
        end

        # :nodoc:
        def records=(records : Array(T))
          @records = records
        end

        def push(record : T)
          if @relation.persisted?
            record.update({ @foreign_key => @relation.id })
          else
            record.attributes = { @foreign_key => @relation.id }
          end
          to_a << record if loaded?
        end

        def <<(record : T)
          push(record)
        end

        # :nodoc:
        def save
          each(&.save) if loaded? && @relation.persisted?
        end

        # :nodoc:
        def save!
          each(&.save!) if loaded? && @relation.persisted?
        end

        def build(attributes : Hash)
          record = build
          record.attributes = attributes
          record
        end

        def build
          record = T.new
          push(record)
          record
        end

        def create(attributes : Hash)
          # TODO: raise if @relation isn't persisted (?)
          build(attributes).tap(&.save)
        end

        def create!(attributes : Hash)
          # TODO: raise if @relation isn't persisted (?)
          build(attributes).tap(&.save!)
        end

        def create
          # TODO: raise if @relation isn't persisted (?)
          build.tap(&.save)
        end

        def create
          # TODO: raise if @relation isn't persisted (?)
          build.tap(&.save!)
        end

        def delete(*records : T)
          records.each do |record|
            case @dependent
            when :destroy    then record.destroy
            when :delete_all then record.delete
            else                  record.update({ @foreign_key => nil })
            end
            to_a.delete(record) if loaded?
          end
        end

        def destroy(*records : T)
          records.each do |record|
            record.destroy
            to_a.delete(record) if loaded?
          end
        end

        def clear
          case @dependent
          when :destroy    then destroy
          when :delete_all then delete_all
          else                  update_all({ @foreign_key => nil })
          end
          to_a.clear if loaded?
        end

        def dup
          Query::Executor.new(T, data.dup)
        end
      end

      macro has_many(name, foreign_key = nil, dependent = nil, autosave = true)
        {% name = name.id %}
        {% singular = run("../../support/inflector/singularize", name).strip %}
        {% model_name = singular.camelcase.id %}
        {% relation = @type.name.underscore.id %}
        {% foreign_key = (foreign_key || "#{ relation }_id").id %}

        {% ASSOCIATIONS[name.symbolize] = :has_many %}

        def {{ name }}(reload = false)
          @{{ name }} = nil if reload
          @{{ name }} ||= begin
                            collection = HasManyCollection({{ model_name }})
                              .new(self, {{ foreign_key.stringify }}, {{ dependent }})
                            if id = self.id
                              collection.where!({ {{ foreign_key }}: id })
                            else
                              collection.records = [] of {{ model_name }}
                              collection
                            end
                          end
        end

        def {{ name }}=(records : Array(T) | HasManyCollection(T) | Query::Executor(T))
          transaction do
            removed = {{ name }}
              .where("#{ Frost::Record.connection.quote(T.primary_key) } NOT IN (?)", records.map(&.id).compact)

            {% if dependent == :delete_all %}
              removed.delete_all
            {% elsif dependent == :destroy %}
              removed.destroy
            {% else %}
              removed.update_all({ {{ foreign_key }}: nil })
            {% end %}

            records.each do |record|
              record.{{ relation }} = self
              record.save
            end

            {{ name }}.records = records.to_a
          end
        end

        def {{ singular.id }}_ids
          # TODO: cast array elements to column type (eg: String, Int32, ...)
          {{ name }}.pluck({{ model_name }}.primary_key)
        end

        def {{ singular.id }}_ids=(ids)
          self.{{ name }} = {{ model_name }}.where({ {{ model_name }}.primary_key => ids })
        end

        {% if autosave %}
          protected def handle_validate_{{ name }}_dependency
            if {{ name }} = @{{ name }}
              {{ name }}.each do |record|
                next if record._validating?

                unless record.valid?
                  errors.add(:base, "Some {{ name }} are invalid")
                  return
                end
              end
            end
          end

          protected def handle_after_save_{{ name }}_dependency
            if {{ name }} = @{{ name }}
              {{ name }}.each do |record|
                next if record._saving?
                record.{{ foreign_key }} = id.not_nil!
                record.save
              end
            end
          end
        {% end %}

        {% if dependent %}
          protected def handle_delete_{{ name }}_dependency
            {% if dependent == :destroy || dependent == :delete_all || dependent == :nullify %}
              {{ name }}.clear
            {% elsif dependent == :exception %}
              raise DeleteRestrictionError.new if {{ name }}.any?
            {% end %}
            nil
          end
        {% end %}
      end
    end
  end
end
