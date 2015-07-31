require "uri"
require "../database/postgresql"

module Trail
  class Record
    # TODO: connection pool
    module Connection
      def self.connect(url)
        uri = URI.parse(url)

        case uri.scheme
        when "postgres"
          @@connection = Database::PostgreSQL.new(url)
        else
          raise "unknown connection adapter: #{ uri.scheme }"
        end
      end

      def self.connection
        connect(ENV["DATABASE_URL"]) unless @@connection
        @@connection.not_nil!
      end
    end

    def self.connection
      Connection.connection
    end

    def self.connection(&block)
      with connection yield
    end
  end
end
