require "./string"

module Trail
  module Database
    class PostgreSQL
      module OID
        getter :limit

        class Text < String
          def initialize(@nullable, @limit = nil)
          end

          def to_sql
            if limit = @limit
              "TEXT(#{ limit })"
            else
              "TEXT"
            end
          end
        end
      end
    end
  end
end
