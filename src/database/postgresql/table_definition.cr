require "./column"
require "./oid"

module Frost
  module Database
    class PostgreSQL
      class TableDefinition
        COLUMN_TYPES = %w(
          string text integer float datetime date time boolean uuid json jsonb
        )
        getter name : Symbol
        @pg : PostgreSQL

        def initialize(@pg, @name)
          @columns = [] of Column
        end

        def column(name, type, null = true, limit = nil, default = nil, precision = nil, scale = nil, primary_key = false)
          @columns << Column.new(
            name.to_s,
            OID.from(type, null, limit),
            null: null,
            limit: limit,
            default: default,
            precision: precision,
            scale: scale,
            primary_key: primary_key
          )
        end

        def primary_key(name, type = :serial, null = false, limit = nil, default = nil, precision = nil, scale = nil)
          column(
            name,
            type.to_s,
            null: null,
            limit: limit,
            default: default,
            precision: precision,
            scale: scale,
            primary_key: true
          )
        end

        def timestamps(null = false)
          column(:created_at, :datetime, null: null)
          column(:updated_at, :datetime, null: null)
        end

        {% for type in COLUMN_TYPES %}
          def {{ type.id }}(name, null = true, limit = nil, default = nil, precision = nil, scale = nil, primary_key = false)
            column(
              name,
              {{ type }},
              null: null,
              limit: limit,
              default: default,
              precision: precision,
              scale: scale,
              primary_key: primary_key
            )
          end
        {% end %}

        def to_sql
          String.build do |sql|
            sql << "CREATE TABLE IF NOT EXISTS " << @pg.quote(@name) << " (\n"

            @columns.each_with_index do |column, index|
              sql << ",\n" unless index == 0
              sql << "  " << @pg.quote(column.name) << " "
              sql << column.type.to_sql
              sql << " PRIMARY KEY" if column.primary_key?
             #sql << " UNIQUE" if column.unique?
              sql << " NOT NULL" unless column.null?
              if column.default?(drop_functions: false)
                sql << " DEFAULT " << @pg.escape(column.default(drop_functions: false), skip_functions: true)
              end
            end

            sql << "\n)"
          end
        end
      end
    end
  end
end
