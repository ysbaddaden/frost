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

      {% for method in %w(all find find_by find_by? first first? last last? to_a exists?) %}
        # Delegates to `Trail::Record::Query::Executor#{{ method.id }}`
        delegate :{{ method.id }}, :query
      {% end %}

      def count(column_name = "*", distinct = false, group = nil : Nil)
        query.count(column_name, distinct, nil)
      end

      def count(column_name = "*", distinct = false, group = "" : String | Symbol)
        query.count(column_name, distinct, group)
      end

      def count(column_name = "*", distinct = false, group = nil : Array | Tuple)
        query.count(column_name, distinct, group)
      end

      private def query
        Query::Executor.new(self)
      end
    end

    module Query
      # TODO: calculations (minimum, maximum, average)
      # TODO: #sample
      class Executor(T) < Trail::Query::Builder
        # :nodoc:
        def initialize(@klass : T.class, data = Trail::Query::Data.new)
          super(@klass.table_name, Record.connection, data)
        end

        macro method_missing(name, args, block)
          {% if args.size > 0 %}
            @klass.{{ name.id }}({{ args.argify }}, context: self)
          {% else %}
            @klass.{{ name.id }}(context: self)
          {% end %}
        end

        def to_a
          @records ||= begin
                         records = [] of T

                         Record.connection.select(to_sql) do |row|
                           records << @klass.from_pg_result(row)
                         end

                         records
                       end
        end

        def loaded?
          !!@records
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

        def size
          if loaded?
            to_a.size
          else
            count
          end
        end

        def any?
          size > 0
        end

        def exists?(id)
          where({ @klass.primary_key => id }).any?
        end

        def empty?
          size == 0
        end

        def all
          self
        end

        # TODO: raise if data.group isn't empty (use count(group: columns) instead)
        def count(column_name = "*", distinct = false, group = nil : Nil)
          distinct = distinct ? "DISTINCT " : ""
          column_name = with_table_name(column_name.to_s) unless column_name == "*"
          sql = select("COUNT(#{ distinct }#{ column_name })").to_sql
          Record.connection.select_values(sql)[0][0] as Int64
        end

        def count(column_name = "*", distinct = false, group = "" : String | Symbol)
          distinct = distinct ? "DISTINCT " : ""
          quoted_column_name = column_name == "*" ? "*" : with_table_name(column_name.to_s)
          as_column_name = column_name == "*" ? "count_all" : "count_#{ column_name }"
          sql = self.group(group).select(group, "COUNT(#{ distinct }#{ quoted_column_name }) AS #{ as_column_name }").to_sql

          rows = Record.connection.select_values(sql)
          rows.each_with_object(Hash(typeof(rows[0][0]), Int64).new) do |row, hash|
            hash[row[0]] = row[1] as Int64
          end
        end

        def count(column_name = "*", distinct = false, group = Tuple(String).new : Tuple)
          distinct = distinct ? "DISTINCT " : ""
          quoted_column_name = column_name == "*" ? "*" : with_table_name(column_name.to_s)
          as_column_name = column_name == "*" ? "count_all" : "count_#{ column_name }"
          sql = self.group(*group).select(*group, "COUNT(#{ distinct }#{ quoted_column_name }) AS #{ as_column_name }").to_sql

          rows = Record.connection.select_values(sql)
          rows.each_with_object(Hash(Array(typeof(rows[0][0])), Int64).new) do |row, hash|
            hash[row[0 ... -1]] = row[-1] as Int64
          end
        end

        # Finds a record by id. Raises RecordNotFound if it can't be found.
        # ```
        # post = Post.find(1)
        # # => SELECT * FROM posts WHERE id = 1 LIMIT 1;
        #
        # comment = post.comments.find("2")
        # # => SELECT * FROM comments WHERE post_id = 1 AND id = '2' LIMIT 1;
        # ```
        def find(id)
          find_by?({ @klass.primary_key => id }) ||
            raise RecordNotFound.new("Couldn't find #{ @klass.name } for #{ @klass.primary_key }=#{ id}")
        end

        # Finds a record by attributes but raises RecordNotFound if no record
        # can be found.
        #
        # ```
        # post = Post.find_by({ blog_id: 1, urlname: "hello-world" })
        # # => SELECT * FROM posts WHERE blog_id = 1 AND urlname = 'hello-world' LIMIT 1;
        # ```
        def find_by(attributes : Hash)
          find_by?(attributes) ||
            raise RecordNotFound.new("Couldn't find #{ @klass.name } for #{ attributes.inspect }")
        end

        # Same as `#find_by`, but returns nil if no record can be found.
        def find_by?(attributes : Hash)
          where(attributes).first?
        end

        # Returns the first record matching the query. Raises `RecordNotFound`
        # if no record can be found.
        #
        # ```
        # post = Post.first
        # # => SELECT * FROM posts ORDER BY id ASC LIMIT 1;
        #
        # post = Post.order(:published_at).first
        # # => SELECT * FROM posts ORDER BY published_at ASC LIMIT 1;
        # ```
        def first
          first? || raise RecordNotFound.new("Couldn't find first #{ @klass.name }")
        end

        # Same as `#first` but Returns nil if no record can be found.
        def first?
          Record.connection.select(limit(1).to_sql) do |row|
            return @klass.from_pg_result(row)
          end
          nil
        end

        # Returns the last record matching the query, reversing the ORDER BY
        # requirements. Raises RecordNotFound if no record can be found.
        #
        # ```
        # post = Post.last
        # # => SELECT * FROM posts ORDER BY id DESC LIMIT 1;
        #
        # post = Post.order(:published_at, :desc).last
        # # => SELECT * FROM posts ORDER BY published_at ASC LIMIT 1;
        # ```
        def last
          last? || raise RecordNotFound.new("Couldn't find last #{ @klass.name }")
        end

        # Same as `#last` but returns nil if no record can be found.
        def last?
          query = dup

          if orders = query.data.orders
            orders.each { |col, dir| orders[col] = dir == "ASC" ? "DESC" : "ASC" }
            query.first?
          else
            order({ id: :desc }).first?
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
        #       time, since the attr_name is only known at runtime. The elements
        #       type is thus the union type of all the possible types that the
        #       database driver can return.
        #
        # TODO: accept variadic arguments, so we can pluck many columns at once,
        #       or many a tuple to have a different method signature.
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

        def destroy
          each { |record| record.destroy }
        end

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
