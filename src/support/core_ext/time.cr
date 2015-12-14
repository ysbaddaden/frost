module Frost
  module Support
    module CoreExt
      module Time
        module ClassMethods
          def at(timestamp)
            epoch(timestamp)
          end
        end

        def to_i
          epoch
        end

        def to_f
          epoch_ms / 1000.0
        end
      end
    end
  end
end

# :nodoc:
struct Time
  include Frost::Support::CoreExt::Time
  extend Frost::Support::CoreExt::Time::ClassMethods
end
