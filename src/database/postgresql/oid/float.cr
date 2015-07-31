require "./type"

module Trail
  module Database
    class PostgreSQL
      module OID
        class Float < Type
          getter :limit

          def initialize(@nullable, limit = 4)
            @limit = limit || 4
          end

          def to_crystal
            super case @limit
                  when 4 then "::Float32 | ::Int32 | ::String"
                  when 8 then "::Float64 | ::Int32 | ::Int64 | ::String"
                  end
          end

          def with_crystal(value)
            case @limit
            when 4 then "#{ value }_f32"
            when 8 then "#{ value }_f64"
            end
          end

          def to_cast
            super case @limit
                  when 4 then "value.to_f32"
                  when 8 then "value.to_f64"
                  end
          end

          def to_sql
            case @limit
            when 4 then "float4"
            when 8 then "float8"
            end
          end
        end
      end
    end
  end
end
