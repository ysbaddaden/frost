module Trail
  class Record
    # TODO: keep a list of associations (so #save and #delete can access them)
    # TODO: customize dependent (delete, destroy, nullify)
    # TODO: pass nullable column state (?)
    module Associations
    end
  end
end

require "./associations/belongs_to"
require "./associations/has_many"
require "./associations/has_one"
