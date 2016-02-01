module Frost
  module Support
    module CoreExt
      module Time
        ISO8601 = "%FT%T%:z"
        RFC822 = "%a, %-d %b %Y %H:%M:%S %z"
        JSON = "%FT%T.%LZ"

        # :nodoc:
        module Parsers
          JSON = /\A(\d+)-(\d+)-(\d+)[T ](\d+):(\d+):(\d+)(?:\.(\d+))?(Z| ?[-+]\d+)\Z/
          ISO8601 = /\A(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)(.+)\Z/
          RFC822 = /\A\w+, (\d+) (\w+) (\d+) (\d+):(\d+):(\d+) (.+)\Z/
          ZONE = /([-+])(\d\d)(\d\d)\Z/
          COLUMN_ZONE = /([-+])(\d\d):(\d\d)\Z/
        end

        module ClassMethods
          def at(timestamp)
            epoch(timestamp)
          end

          def parse(string : String)
            zh = zm = 0

            case string
            when Parsers::JSON
              ms = $7?.try(&.to_i) || 0
              y, m, d, h, mm, s = $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i
              if $8 =~ Parsers::ZONE
                zh, zm = $2.to_i, $3.to_i
                zh, zm = -zh, -zm if $1 == "-"
              end

            when Parsers::ISO8601
              y, m, d, h, mm, s, ms = $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, 0
              if $7 =~ Parsers::COLUMN_ZONE
                zh, zm = $2.to_i, $3.to_i
                zh, zm = -zh, -zm if $1 == "-"
              end

            when Parsers::RFC822
              m = case $2
                  when "Jan" then 1
                  when "Feb" then 2
                  when "Mar" then 3
                  when "Apr" then 4
                  when "May" then 5
                  when "Jun" then 6
                  when "Jul" then 7
                  when "Aug" then 8
                  when "Sep" then 9
                  when "Oct" then 10
                  when "Nov" then 11
                  when "Dec" then 12
                  else raise "Can't parse #{string} as Time"
                  end
              y, d, h, mm, s, ms = $3.to_i, $1.to_i, $4.to_i, $5.to_i, $6.to_i, 0
              if $7 =~ Parsers::ZONE
                zh, zm = $2.to_i, $3.to_i
                zh, zm = -zh, -zm if $1 == "-"
              end

            else
              raise "Can't parse #{string} as Time"
            end

            time = ::Time.new(y, m, d, h, mm, s, ms, kind: Time::Kind::Utc)
            if zh
              time -= zh.hours
            end
            if zm
              time -= zm.minutes
            end
            time
          end
        end

        def to_i
          epoch
        end

        def to_f
          epoch_ms / 1000.0
        end

        def iso8601
          to_s(ISO8601)
        end

        def iso8601(io)
          to_s(ISO8601, io)
        end

        def rfc822
          to_s(RFC822)
        end

        def rfc822(io)
          to_s(RFC822, io)
        end

        def to_json
          to_utc.to_s(JSON)
        end

        def to_json(io)
          io << '"'
          to_utc.to_s(JSON, io)
          io << '"'
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
