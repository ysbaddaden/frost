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
          (to_utc.ticks - ::Time::UnixEpoch) / ::Time::Span::TicksPerSecond
        end

        def to_f
          (to_utc.ticks - ::Time::UnixEpoch) / ::Time::Span::TicksPerMillisecond / 1000.0
        end

        def iso8601
          to_s("%FT%T%:z")
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
