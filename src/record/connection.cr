require "uri"
require "../database/postgresql"
require "./errors"

module Trail
  class Record
    # TODO: connection pool
    module Connection
      struct Configuration
        property :adapter, :host, :port, :username, :password, :database

        def self.from(url)
          uri = URI.parse(url)
          database = uri.path.to_s.sub('/', "")
          new(uri.scheme, uri.host, uri.port, uri.user, uri.password, database)
        end

        def initialize(@adapter, @host, @port, @username, @password, @database)
        end

        def url
          if username || password
            "#{ adapter }://#{ username }:#{ password }@#{ host }/#{ database }"
          else
            "#{ adapter }://#{ host }/#{ database }"
          end
        end
      end

      def self.connect(config = configuration)
        case config.adapter
        when "postgres"
          @@connection = Database::PostgreSQL.new(config.url)
        else
          raise "unknown connection adapter: #{ config.adapter }"
        end
      end

      def self.connection
        connect unless @@connection
        @@connection.not_nil!
      end

      # TODO: read configuration from config/database.yml
      def self.configuration
        @@configuration ||= begin
          if url = ENV["DATABASE_URL"]
            Configuration.from(url)
          else
            raise ConnectionError.new("Missing DATABASE_URL environment variable")
          end
        end
      end
    end

    def self.connection
      Connection.connection
    end

    def self.connection(&block)
      with connection yield connection
    end
  end
end
