module Frost
  abstract class Record
    module Callbacks

      macro define_model_callbacks(*names)
        {% for name in names %}
          protected def run_{{ name.id }}_callbacks
            if self.responds_to?(:before_{{ name.id }})
              return if self.before_{{ name.id }} == false
            end

            success = if self.responds_to?(:around_{{ name.id }})
                        self.around_{{ name.id }} { yield }
                      else
                        yield
                      end

            if self.responds_to?(:after_{{ name.id }})
              self.after_{{ name.id }}
            end

            success
          end
        {% end %}
      end

    end
  end
end
