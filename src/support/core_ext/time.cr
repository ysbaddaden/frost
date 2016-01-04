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

        def rfc822
          to_s("%a, %d %b %Y %H:%M:%S %z")
        end

        def to_json
          to_utc.to_s("%FT%T.%LZ")
        end

        def to_json(io)
          io << '"' << to_json << '"'
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
