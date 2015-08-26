require "./type"

module Trail
  module Database
    class PostgreSQL
      module OID
        class Bool < Type
          TRUENESS = [1, "1", true, "t", "true", "on", "y", "yes"]
          FALSENESS = [0, "0", false, "f", "false", "off", "n", "no"]

          def initialize(@nullable)
          end

          def to_crystal
            super "::Bool | ::Int8 | ::Int16 | ::Int32 | ::Int64 | ::String"
          end

          def to_cast
            super "#{ self.class.name }::TRUENESS.includes?(value)"
          end

          def to_sql
            "BOOLEAN"
          end
        end
      end
    end
  end
end
