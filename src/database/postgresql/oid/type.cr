module Frost
  module Database
    class PostgreSQL
      module OID

        abstract class Type
          def initialize(@nullable = false)
          end

          def to_crystal(str)
            if @nullable
              if str.not_nil!.index("|")
                "#{ str } | ::Nil"
              else
                "#{ str }?"
              end
            else
              str
            end
          end

          def as_crystal
            to_crystal.to_s.split(" | ").first.gsub(/\?/, "")
          end

          def with_crystal(value)
            value
          end

          def to_cast(str)
            if @nullable
              "if value.is_a?(Nil)\n    nil\n  else\n    #{ str }\n  end"
            else
              str
            end
          end

          def to_s
            self.class.name.demodulize.downcase
          end
        end

      end
    end
  end
end
