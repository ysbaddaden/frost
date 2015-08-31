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
      # TODO: calculations (count, any?, empty?, minimum, maximum, average)
      # TODO: #sample
      # TODO: #count, #empty?, #any?
      class Executor(T) < Trail::Query::Builder
        # :nodoc:
        def initialize(@klass : T.class, data = Trail::Query::Data.new)
          super(@klass.table_name, Record.connection, data)
        end

        def to_a
          @records ||= begin
                         records = [] of T

                         Record.connection.select(to_sql) do |result, row|
                           records << @klass.from_pg_result(result, row)
                         end

                         records
                       end
        end

        def each
          to_a.each { |record| yield record }
        end

        def each_with_index
          to_a.each_with_index { |record, index| yield record, index }
        end

        def inject
          to_a.inject { |acc, record| yield acc, record }
        end

        def inject(memo)
          to_a.inject(memo) { |acc, record| yield acc, record }
        end

        def map
          to_a.map { |record| yield record }
        end

        def map_with_index
          to_a.map_with_index { |record, index| yield record, index }
        end

        # OPTIMIZE: execute SQL COUNT until @records is loaded
        def size
          to_a.size
        end

        def all
          self
        end

        #def count
        #  query = select("COUNT(*)").to_sql
        #  Record.connection.select_values(select("COUNT(*)").to_sql)[0][0] as Int32
        #end

        # Finds a record by id. Raises RecordNotFound if it can't be found.
        # ```
        # post = Post.find(1)
        # # => SELECT * FROM posts WHERE id = 1 LIMIT 1;
        #
        # comment = post.comments.find("2")
        # # => SELECT * FROM comments WHERE post_id = 1 AND id = '2' LIMIT 1;
        # ```
        def find(id)
          find_by!({ @klass.primary_key => id })
        end

        # Finds a record by attributes. Returns nil if it can't be found.
        # ```
        # post = Post.find_by({ blog_id: 1, urlname: "hello-world" })
        # # => SELECT * FROM posts WHERE blog_id = 1 AND urlname = 'hello-world' LIMIT 1;
        # ```
        def find_by(attributes : Hash)
          where(attributes).first
        end

        # Finds a record by attributes but raises RecordNotFound if it can't be found.
        def find_by!(attributes : Hash)
          if record = find_by(attributes)
            record
          else
            raise RecordNotFound.new("No #{ @klass.name } found with #{ attributes.inspect }")
          end
        end

        # Returns the first record matching the query. Returns nil if no record
        # can be found.
        #
        # ```
        # post = Post.first
        # # => SELECT * FROM posts ORDER BY id ASC LIMIT 1;
        #
        # post = Post.order(:published_at).first
        # # => SELECT * FROM posts ORDER BY published_at ASC LIMIT 1;
        # ```
        def first
          Record.connection.select(limit(1).to_sql) do |result, _|
            return @klass.from_pg_result(result, 0)
          end
          nil
        end

        # Returns the last record matching the query, reversing the ORDER BY
        # requirements. Returns nil if no record can be found.
        #
        # ```
        # post = Post.last
        # # => SELECT * FROM posts ORDER BY id DESC LIMIT 1;
        #
        # post = Post.order(:published_at, :desc).last
        # # => SELECT * FROM posts ORDER BY published_at ASC LIMIT 1;
        # ```
        def last
          query = dup

          if orders = query.data.orders
            orders.each { |col, dir| orders[col] = dir == "ASC" ? "DESC" : "ASC" }
            query.first
          else
            order({ id: :desc }).first
          end
        end

        # Returns an Array of all the values of a single column matching the
        # query. This will only request this column from the database and will
        # only build the resulting Array.
        #
        # ```
        # titles = Post.pluck(:title)
        # # = ["Hello World", "My First Post", ...]
        # ```
        #
        # NOTE: the Array elements type is impossible to cast down at compile
        # time, since the attr_name is only known at runtime. The elements type
        # is thus the union type of all the possible types that the database
        # driver can return.
        #
        # TODO: accept variadic arguments, so we can pluck many columns at once.
        def pluck(attr_name)
          query = dup
          query.data.selects = [attr_name.to_s]
          Record.connection.select_values(query.to_sql).map(&.first)
        end

        # Deletes all records matching the query.
        # ```
        # Comment.where({ post_id: 1 }).delete_all
        # # => DELETE * FROM comments WHERE post_id = 1;
        # ```
        def delete_all
          Record.connection.execute(to_sql(Query::Type::DELETE))
        end

        # Updates the column values of all records matching the query.
        # ```
        # Comment.where({ spam: nil }).update_all({ spam: true })
        # # => UPDATE comments SET spam = 't' WHERE spam IS NULL;
        # ```
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

        def inspect(io)
          to_a.inspect(io)
        end
      end
    end
  end
end
