module Frost
  abstract class Record
    # :nodoc:
    module SchemaMigration
      QUERY = "SELECT version FROM schema_migrations ;"

      def self.versions
        Record.connection do |conn|
          conn.execute({String}, QUERY).rows.map(&.first)
        end
      end

      def self.pending_versions
        Frost::Record.migrations.map(&.version) - versions
      end

      def self.pending?
        pending_versions.any?
      end

      def self.migrated?(version)
        Record.connection do |conn|
          sql = "SELECT COUNT(*) FROM schema_migrations WHERE version = #{ conn.escape(version) };"
          conn.execute({Int64}, sql).rows.first.first > 0
        end
      end

      def self.create_table
        Record.connection do |conn|
          conn.create_table("schema_migrations", id: false) do |t|
            t.primary_key :version, :string, null: false, limit: 14
          end
        end
      end

      def self.insert(version)
        Record.connection do |conn|
          conn.execute("INSERT INTO schema_migrations VALUES (#{ conn.escape(version) });")
        end
      end

      def self.delete(version)
        Record.connection do |conn|
          conn.execute("DELETE FROM schema_migrations WHERE version = (#{ conn.escape(version) });")
        end
      end

      def self.dump(filename)
        Record.connection do |conn|
          values = conn.execute({String}, QUERY).rows.map { |row| conn.escape(row.first) }
          return if values.empty?

          File.open(filename, "a") do |f|
            f << "INSERT INTO schema_migrations (version) VALUES (#{ values.join("), (") });\n"
          end
        end
      end
    end

    SchemaMigration.create_table
  end
end
