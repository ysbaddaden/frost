require "./oid/*"

module Frost
  module Database
    class PostgreSQL
      module OID

        # TODO: json, jsonb, xml
        # TODO: point, lseg, path, box, polygon, line, circle
        def self.from(row : ::Hash)
          udt_name = row["udt_name"] as ::String
          nullable = row["is_nullable"] == "YES"

          case udt_name
          when "bool"
            Bool.new(nullable)
          when "int2"
            Integer.new(nullable, 2)
          when "int4"
            Integer.new(nullable, 4)
          when "int8"
            Integer.new(nullable, 8)
          when "float4"
            Float.new(nullable, 4)
          when "float8"
            Float.new(nullable, 8)
          when "timestamp"
            Datetime.new(nullable)
          when "varchar", "char"
            String.new(nullable, row["character_maximum_length"] as ::Int32)
          when "text"
            Text.new(nullable, row["character_maximum_length"]? as ::Int32?)
          when "uuid"
            UUID.new(nullable)
          else
            Generic.new(nullable, udt_name)
          end
        end

        def self.from(type : ::Symbol | ::String, nullable, limit)
          case type.to_s
          when "boolean"  then Bool.new(nullable)
          when "integer"  then Integer.new(nullable, limit)
          when "serial"   then Serial.new(nullable, limit)
          when "float"    then Float.new(nullable, limit)
          when "datetime" then Datetime.new(nullable)
          when "string"   then String.new(nullable, limit)
          when "text"     then Text.new(nullable, limit)
          when "uuid"     then UUID.new(nullable)
          else                 Generic.new(type, nullable)
          end
        end

      end
    end
  end
end
