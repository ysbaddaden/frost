require "pg"
require "./pg_ext"
require "./errors"
require "./transaction"
require "./postgresql/table"
require "./postgresql/table_definition"

module Trail
  module Database
    class PostgreSQL
      getter :conn

      def initialize(url)
        @conn = PG.connect(url)
        @transactions = [] of Transaction
      rescue ex : PG::ConnectionError
        raise ConnectionError.new(ex.message)
      end

      def execute(sql)
        log(sql)
        conn.exec(sql)
      rescue ex : PG::ResultError
        raise StatementInvalid.new(ex.message)
      end

      def trail_execute(sql)
        log(sql)
        conn.trail_exec(sql)
      rescue ex : PG::ResultError
        raise StatementInvalid.new(ex.message)
      end

      def execute(types, sql)
        log(sql)
        conn.exec(types, sql)
      rescue ex : PG::ResultError
        raise StatementInvalid.new(ex.message)
      end

      def select_one(sql)
        execute(sql).to_hash.first?
      end

      def select_all(sql)
        execute(sql).to_hash
      end

      def select(sql)
        result = trail_execute(sql)
        result.each { |row| yield row }
      end

      def select_values(sql)
        execute(sql).rows
      end

      def insert(table_name, attributes, primary_key = "id", primary_key_type = Int32)
        sql = String.build do |str|
          str << "INSERT INTO " << quote(table_name) << " ("
          str << attributes.keys.map { |attr| quote(attr) }.join(", ")
          str << ") VALUES ("
          str << attributes.values.map { |value| escape(value) }.join(", ")
          str << ") RETURNING #{ primary_key } ;"
        end
        if row = execute({primary_key_type}, sql).rows.first?
          row.first?
        end
      end

      def table(name)
        Table.new(self, name)
      end

      def tables
        sql = "SELECT tablename FROM pg_tables WHERE schemaname = 'public'"
        select_values(sql).map { |row| Table.new(self, row[0]) }
      end

      def primary_key(table_name)
        result = execute(String.build do |sql|
          sql << "SELECT pg_attribute.attname FROM pg_attribute "
          sql << "INNER JOIN pg_constraint ON pg_attribute.attrelid = pg_constraint.conrelid AND pg_attribute.attnum = any(pg_constraint.conkey) "
          sql << "WHERE pg_constraint.contype = 'p' AND pg_constraint.conrelid = " << escape(table_name) << "::regclass ;"
        end)
        if row = result.rows[0]?
          row[0]?
        end
      end

      def create_table(name, id = :serial, primary_key = :id, default = nil, force = false)
        table = TableDefinition.new(self, name)
        table.primary_key primary_key, type: id, default: default if id

        yield table

        drop_table name if force
        execute table.to_sql
      end

      def drop_table(name)
        execute "DROP TABLE IF EXISTS #{ quote(name) }"
      end

      def add_index(table_name, column_name, name = nil, unique = false, using = :btree)
        add_index(table_name, {column_name}, name, unique, using)
      end

      def add_index(table_name, column_names : Tuple, name = nil, unique = false, using = :btree)
        name ||= "index_#{ table_name }_on_#{ column_names.join("_and_") }"

        execute(String.build do |sql|
          sql << "CREATE"
          sql << " UNIQUE" if unique
          sql << " INDEX " << name
          sql << " ON " << quote(table_name)
          sql << " USING " << using if using
          sql << " (" << column_names.map { |column_name| quote(column_name) }.join(", ") << ")"
        end)
      end

      # :nodoc:
      def transaction
        Transaction.new(self).tap(&.begin)
      end

      def transaction(requires_new = false)
        if Transaction.any? && !requires_new
          return yield
        end

        transaction = self.transaction

        begin
          yield
        rescue ex
          transaction.rollback
          raise ex
        else
          transaction.commit
        end
      ensure
        if transaction
          transaction.rollback unless transaction.completed?
        end
      end

      def extensions
        execute("SELECT extname from pg_extension").rows.map(&.first)
      end

      def enable_extension(name)
        execute "CREATE EXTENSION IF NOT EXISTS #{ quote(name) }"
      end

      def disable_extension(name)
        execute "DROP EXTENSION IF EXISTS #{ quote(name) }"
      end

      def quote(identifier)
        conn.escape_identifier(identifier.to_s)
      end

      def escape(value, skip_functions = false)
        case value
        when Int, Float
          return value.to_s
        when Bool
          return value ? "'t'" : "'f'"
        when String
          if skip_functions && value =~ /\(.*\)/
            return value
          end
        when Nil
          return "NULL"
        end

        conn.escape_literal(value.to_s)
      end

      private def log(sql)
        if t = Trail
          if t.responds_to?(:logger)
            t.logger.debug(sql)
          end
        end
      end
    end
  end
end
