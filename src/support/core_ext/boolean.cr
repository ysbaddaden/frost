require "../blank"

module Frost
  module Support
    module CoreExt
      module Bool
        # `false` is always blank whereas `true` is never blank.
        def blank?
          self == false
        end
      end
    end
  end
end

# :nodoc:
struct Bool
  include Frost::Support::Blank
  include Frost::Support::CoreExt::Bool
end
