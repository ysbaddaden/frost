require "./connection"
require "./migration"

module Frost
  class Record
    module Schema
      # NOTE: DEPRECATED (use dump_structure and load_structure instead)
      def self.load
        Record.connection do |conn|
          conn.transaction { with conn yield }
        end
      end

      def self.load_structure(filename)
        process("psql", {"--quiet", "-f", filename, Record::Connection.configuration.database})
      end

      def self.dump_structure(filename)
        process("pg_dump", {"--schema-only", "--no-acl", "--no-owner", "-f", filename, Record::Connection.configuration.database})
        SchemaMigration.dump(filename)
      end

      private def self.process(command, args)
        return if Process.run(command, args, env: psql_env).success?
        puts "Failed to execute:\n#{ command } #{ args.join(' ') }\n\nPlease make sure that '#{ command }' is available in your PATH."
        exit 1
      end

      private def self.psql_env
        config = Record::Connection.configuration
        hsh = {} of String => String

        if host = config.host
          hsh["PGHOST"] = host
        end
        if port = config.port
          hsh["PGPORT"] = port.to_s
        end
        if username = config.username
          hsh["PGUSER"] = username
        end
        if password = config.password
          hsh["PGPASSWORD"] = password
        end

        hsh
      end
    end
  end
end
