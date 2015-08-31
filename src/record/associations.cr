module Trail
  class Record
    # TODO: customize foreign_key
    # TODO: customize dependent (delete, destroy, nullify)
    # TODO: pass nullable column state
    module Associations
      macro belongs_to(name)
        {{ run "./associations/belongs_to.cr", name }}
      end

      macro has_one(name)
        {{ run "./associations/has_one.cr", name }}
      end

      macro has_many(name)
        {{ run "./associations/has_many.cr", name, @type.name.underscore }}
      end
    end
  end
end
