require "./type"

module Frost
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

          def to_cast
            ::String.build do |str|
              str << "case value\n"
              str << "  when Nil  then nil\n" if @nullable
              str << "  when Time then value\n"
              str << "  when Int  then Time.epoch(value)\n"
              str << "  else           Time.parse(value.to_s)\n"
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
