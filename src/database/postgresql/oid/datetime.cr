require "./type"

module Trail
  module Database
    class PostgreSQL
      module OID
        class Datetime < Type
          getter :limit

          def initialize(@nullable, limit = 4)
            @limit = limit || 4
          end

          def to_crystal
            super "::Time | ::Int32 | ::Int64 | ::String"
          end

          # TODO: parse datetime from String, using different common patterns
          #       (eg: JSON, HTTP Header, ...)
          def to_cast
            ::String.build do |str|
              str << "case value\n"
              str << "  when Nil  then nil\n" if @nullable
              str << "  when Time then value\n"
              str << "  when Int  then Time.at(value)\n"
              str << "  else           raise \"TODO: parse datetimes from strings\"\n"
              str << "  end"
            end
          end

          def to_sql
            "timestamp"
          end
        end
      end
    end
  end
end
