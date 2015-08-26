require "./column"

module Trail
  module Database
    class PostgreSQL
      class Table
        getter :name

        def initialize(@pg, name)
          @name = name.to_s
        end

        def columns
          @columns ||= begin
            sql = "SELECT * FROM information_schema.columns WHERE table_name = '#{ name }' ;"
            primary_key = @pg.primary_key(name)

            @pg.execute(sql).to_hash.map do |row|
              Column.from(row, primary_key: row["column_name"] == primary_key)
            end
          end
        end

        def primary_key
          @primary_key ||= columns.find(&.primary_key?).try(&.name)
        end

        def primary_key_type
          @primary_key_type ||= columns.find(&.primary_key?).try(&.as_crystal)
        end

        def primary_key?
          primary_key != nil
        end

        def attribute_names
          columns.map(&.name)
        end
      end
    end
  end
end
