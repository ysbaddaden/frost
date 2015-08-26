require "json"
require "./oid"

module Trail
  module Database
    class PostgreSQL
      class Column
        def self.from(row, primary_key = false)
          name = row["column_name"] as String
          type = OID.from(row)

          if type.responds_to?(:limit)
            limit = type.limit
          end

          null = row["is_nullable"] == "YES"
          precision = row["numeric_precision"] && row["numeric_precision"] as Int32
          scale = row["numeric_scale"] && row["numeric_scale"] as Int32

          new(name, type, limit, null, row["column_default"], precision, scale, primary_key)
        end

        property :name
        property :type
        property :limit
        property :default
        property :precision
        property :scale

        def initialize(@name : String,
                       @type,
                       @limit = nil,
                       @null = true,
                       @default = nil,
                       @precision = nil,
                       @scale = nil,
                       @primary_key = false)
        end

        def default(drop_functions = true)
          default = @default
          unless default.is_a?(Nil) || (drop_functions && default =~ /\(.*\)/)
            default
          end
        end

        def default_with_type
          if default?
            type.with_crystal(default)
          end
        end

        def default?(drop_functions = true)
          default(drop_functions) != nil
        end

        def null?
          @null == true
        end

        def primary_key?
          !!@primary_key
        end

        # Delegates to `type`
        delegate :to_crystal, :type

        # Delegates to `type`
        delegate :as_crystal, :type

        # Delegates to `type`
        delegate :to_cast, :type
      end
    end
  end
end
