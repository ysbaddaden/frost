module Trail
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
  include Trail::Support::CoreExt::Time
  extend Trail::Support::CoreExt::Time::ClassMethods
end
