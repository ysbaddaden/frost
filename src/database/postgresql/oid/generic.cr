require "./string"

module Frost
  module Database
    class PostgreSQL
      module OID
        class Generic < String
          def initialize(@name, @nullable)
          end

          def to_sql
            @name
          end
        end
      end
    end
  end
end
