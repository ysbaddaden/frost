require "./string"

module Trail
  module Database
    class PostgreSQL
      module OID
        class UUID < String
          def initialize(@nullable)
          end

          def to_crystal
            super "::String"
          end

          def to_sql
            "UUID"
          end
        end
      end
    end
  end
end
