module Trail
  class Record
    # TODO: keep a list of associations (so #save and #delete can access them)
    # TODO: customize dependent (delete, destroy, nullify)
    # TODO: customize foreign_key
    # TODO: pass nullable column state (?)
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
