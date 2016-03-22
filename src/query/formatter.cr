module Frost
  module Query
    enum Type
      SELECT
      UPDATE
      DELETE
    end

    # :nodoc:
    FUNCTION_CALL = /[\w_]+\(.*?\)/

    # TODO: make it a class (?)
    module Formatter
      # FIXME: don't quote when column name is a function, eg: COUNT(*)
      def select_clause(sql)
        if selects = data.selects
          columns = selects.compact.uniq

          if columns.any?
            columns.each_with_index do |column_name, index|
              sql << ", " unless index == 0

              if column_name =~ FUNCTION_CALL
                sql << column_name.to_s
              else
                sql << with_table_name(column_name.to_s)
              end
            end

            return
          end
        end

        sql << "*"
      end

      def where_clause(sql)
        if conditions = data.wheres
          sql << " WHERE (" << conditions.join(") AND (") << ")"
        end
      end

      def join_clause(sql)
        if joins = data.joins
          joins.each { |join| sql << " " << join }
        end
      end

      def group_clause(sql)
        if groups = data.groups
          columns = groups.compact
            .map { |column_name| with_table_name(column_name) }
            .uniq
          return if columns.empty?
          sql << " GROUP BY " << columns.join(", ")
        end

        if conditions = data.havings
          sql << " HAVING (" << conditions.join(") AND (") << ")"
        end
      end

      def order_clause(sql)
        if orders = data.orders
          sql << " ORDER BY " << orders.map do |column, direction|
            "#{ with_table_name(column) } #{ direction }"
          end.join(", ")
        end
      end

      def limit_clause(sql)
        sql << " LIMIT #{ data.limit }" if data.limit
        sql << " OFFSET #{ data.offset }" if data.offset
      end

      def update_clause(sql)
        sql << "SET "
        data.updates.not_nil!.each_with_index do |attr, value, index|
          sql << ", " unless index == 0
          sql << adapter.quote(attr) << " = " << adapter.escape(value)
        end
      end

      def to_sql(type : Type = Type::SELECT)
        String.build do |sql|
          case type
          when Type::SELECT
            sql << "SELECT "
            select_clause(sql)
            sql << " FROM #{ adapter.quote(@table_name) }"
            join_clause(sql)
            where_clause(sql)
            group_clause(sql)
            order_clause(sql)
            limit_clause(sql)
          when Type::UPDATE
            sql << "UPDATE #{ adapter.quote(@table_name) } "
            update_clause(sql)
            where_clause(sql)
            order_clause(sql)
            limit_clause(sql)
          when Type::DELETE
            sql << "DELETE FROM #{ adapter.quote(@table_name) }"
            where_clause(sql)
            order_clause(sql)
            limit_clause(sql)
          end
        end
      end

      def inspect(io : IO)
        data.inspect(io)
      end
    end
  end
end
