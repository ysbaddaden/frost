require "../query/builder"

module Trail
  class Record
    # TODO: pluck(attr_name)
    # TODO: reload
    module Finders
      {% for method in %w(select where group having order reorder limit) %}
        # Delegates to `Trail::Record::Query::Builder#{{ method.id }}`
        delegate :{{ method.id }}, :query
      {% end %}

      {% for method in %w(all find find_by find_by! first last to_a) %}
        # Delegates to `Trail::Record::Query::Executor#{{ method.id }}`
        delegate :{{ method.id }}, :query
      {% end %}

      private def query
        Query::Executor.new(self)
      end
    end

    module Query
      # TODO: Enumerable(T) with .each iterator that delegates to memoized .to_a
      # TODO: all returns self (when Enumerable(T) is in place)
      # TODO: calculations (count, any?, empty?, minimum, maximum, average)
      class Executor(T) < Trail::Query::Builder
        #include Enumerable(T)

        def initialize(@klass : T.class, data = Trail::Query::Data.new)
          super(@klass.table_name, Record.connection, data)
        end

        def to_a
          records = [] of T

          Record.connection.select(to_sql) do |result, row|
            records << @klass.from_pg_result(result, row)
          end

          records
        end

        # Alias for `#to_a` (may eventually return an iterable self).
        def all
          to_a
        end

        #def count
        #  query = select("COUNT(*)").to_sql
        #  Record.connection.select_values(select("COUNT(*)").to_sql)[0][0] as Int32
        #end

        #def each
        #  to_a.each { |record| yield record }
        #end

        def find(id)
          find_by!({ @klass.primary_key => id })
        end

        def find_by(attributes : Hash)
          where(attributes).first
        end

        def find_by!(attributes : Hash)
          if record = find_by(attributes)
            record
          else
            raise RecordNotFound.new("No #{ @klass.name } found with #{ attributes.inspect }")
          end
        end

        def first
          Record.connection.select(limit(1).to_sql) do |result, _|
            return @klass.from_pg_result(result, 0)
          end
          nil
        end

        def last
          query = dup

          if orders = query.data.orders
            orders.each { |col, dir| orders[col] = dir == "ASC" ? "DESC" : "ASC" }
            query.first
          else
            order({ id: :desc }).first
          end
        end

        def pluck(attr_name)
          query = dup
          query.data.selects = [attr_name.to_s]
          Record.connection.select_values(query.to_sql).map(&.first)
        end

        def delete_all
          Record.connection.execute(to_sql(Query::Type::DELETE))
        end

        def update_all(attributes)
          query = dup
          query.data.updates = attributes
          Record.connection.execute(query.to_sql(Query::Type::UPDATE))
        end

        #def destroy
        #  to_a.each { |record| record.destroy }
        #end

        def dup
          self.class.new(@klass, data.dup)
        end
      end
    end
  end
end
