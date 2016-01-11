module Frost
  abstract class Record
    module Associations
      # :nodoc:
      macro generate_associations
        # :nodoc:
        ASSOCIATIONS = {} of Symbol => Symbol
      end

      protected macro def handle_validate_dependencies : Nil
        {% for name, type in ASSOCIATIONS %}
          if self.responds_to?(:handle_validate_{{ name.id }}_dependency)
            self.handle_validate_{{ name.id }}_dependency
          end
        {% end %}
        nil
      end

      protected def handle_save_dependencies
        {% for name, type in ASSOCIATIONS %}
          if self.responds_to?(:handle_before_save_{{ name.id }}_dependency)
            self.handle_before_save_{{ name.id }}_dependency
          end
        {% end %}

        if success = yield
          {% for name, type in ASSOCIATIONS %}
            if self.responds_to?(:handle_after_save_{{ name.id }}_dependency)
              self.handle_after_save_{{ name.id }}_dependency
            end
          {% end %}
        end

        success
      end

      protected macro def handle_delete_dependencies : Nil
        {% for name, type in ASSOCIATIONS %}
          if self.responds_to?(:handle_delete_{{ name.id }}_dependency)
            self.handle_delete_{{ name.id }}_dependency
          end
        {% end %}
        nil
      end
    end
  end
end

require "./associations/belongs_to"
require "./associations/has_many"
require "./associations/has_one"
