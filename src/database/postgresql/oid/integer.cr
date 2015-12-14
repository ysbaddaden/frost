require "./type"

module Frost
  module Database
    class PostgreSQL
      module OID
        class Integer < Type
          getter :limit

          def initialize(@nullable, limit = 4)
            @limit = limit || 4
          end

          def to_crystal
            super case @limit
                  when 2 then "::Int16 | ::Int8 | ::String"
                  when 4 then "::Int32 | ::Int16 | ::Int8 | ::String"
                  when 8 then "::Int64 | ::Int32 | ::Int16 | ::Int8 | ::String"
                  end
          end

          def with_crystal(value)
            case @limit
            when 2 then "#{ value }_i16"
            when 4 then "#{ value }_i32"
            when 8 then "#{ value }_i64"
            end
          end

          def to_cast
            super case @limit
                  when 2 then "value.to_i16"
                  when 4 then "value.to_i32"
                  when 8 then "value.to_i64"
                  end
          end

          def to_sql
            case @limit
            when 2 then "SMALLINT"
            when 4 then "INT"
            when 8 then "BIGINT"
            end
          end
        end
      end
    end
  end
end
