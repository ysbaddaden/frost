require "../blank"

module Trail
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
  include Trail::Support::Blank
  include Trail::Support::CoreExt::Bool
end
