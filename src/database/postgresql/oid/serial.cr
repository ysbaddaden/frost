require "./type"

module Trail
  module Database
    class PostgreSQL
      module OID
        class Serial < Type
          getter :limit

          def initialize(@nullable, limit = 4)
            @limit = limit || 4
          end

          def to_crystal
            super case @limit
                  when 2 then "::UInt8 | ::UInt16 | ::String"
                  when 4 then "::UInt8 | ::UInt16 | ::UInt32 | ::String"
                  when 8 then "::UInt8 | ::UInt16 | ::UInt32 | ::UInt64 | ::String"
                  end
          end

          def to_cast
            super case @limit
                  when 2 then "value.to_u16"
                  when 4 then "value.to_u32"
                  when 8 then "value.to_u64"
                  end
          end

          def to_sql
            case @limit
            when 2 then "SMALLSERIAL"
            when 4 then "SERIAL"
            when 8 then "BIGSERIAL"
            end
          end
        end
      end
    end
  end
end
