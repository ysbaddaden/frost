require "./type"

module Frost
  module Database
    class PostgreSQL
      module OID
        class String < Type
          getter :limit

          def initialize(@nullable, limit = 255)
            @limit = limit || 255
          end

          def to_crystal
            super "::String"
          end

          def to_cast
            super "value.to_s"
          end

          def to_sql
            "VARCHAR(#{ @limit })"
          end
        end
      end
    end
  end
end
