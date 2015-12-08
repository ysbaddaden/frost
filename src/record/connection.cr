require "yaml"
require "uri"
require "http/params"
require "pool/connection"
require "../support/core_ext/nil"
require "../support/core_ext/object"
require "../support/core_ext/string"
require "../database/postgresql"
require "./errors"

module Trail
  class Record
    module Connection
      struct Configuration
        DEFAULT_POOL = 5
        DEFAULT_TIMEOUT = 5.0

        property :adapter, :host, :port, :username, :password, :database, :pool, :timeout

        def self.from(url)
          uri = URI.parse(url)
          database = uri.path.to_s.sub('/', "")
          pool = timeout = nil

          if query = uri.query
            HTTP::Params.parse(query) do |key, value|
              case key
              when "pool"
                pool = value.presence.try(&.to_i)
              when "timeout"
                timeout = value.presence.try(&.to_f)
              end
            end
          end

          new(uri.scheme, uri.host, uri.port, uri.user, uri.password, database, pool, timeout)
        end

        def self.from_yaml(string)
          # FIXME: centralize trail environment
          environment = ENV.fetch("TRAIL_ENV", "development")

          unless (hsh = YAML.load(string)).is_a?(Hash)
            raise ConnectionError.new("Invalid 'database.yml'")
          end

          unless (config = hsh[environment]).is_a?(Hash)
            raise ConnectionError.new("Invalid 'database.yml': missing '#{ environment }' configuration")
          end

          adapter = config["adapter"] as String
          database = config["database"] as String

          if value = config["host"]?.presence
            host = value as String
          end
          if value = config["port"]?.presence
            port = (value as String).try(&.to_i)
          end
          if value = config["username"]?.presence
            username = value as String
          end
          if value = config["password"]?.presence
            password = value as String
          end
          if value = config["pool"]?.presence
            pool = (value as String).try(&.to_i)
          end
          if value = config["timeout"]?.presence
            timeout = (value as String).try(&.to_f)
          end

          new(adapter, host, port, username, password, database, pool, timeout)
        rescue ex : KeyError | TypeCastError
          raise ConnectionError.new("Invalid 'database.yml': #{ ex.message }")
        end

        def initialize(@adapter, @host, @port, @username, @password, @database, @pool, @timeout)
        end

        def url
          if username || password
            "#{ adapter }://#{ username }:#{ password }@#{ host }/#{ database }"
          else
            "#{ adapter }://#{ host }/#{ database }"
          end
        end

        def pool
          @pool || DEFAULT_POOL
        end

        def timeout
          @timeout || DEFAULT_TIMEOUT
        end
      end

      def self.pool
        @@pool ||= ConnectionPool.new(capacity: configuration.pool, timeout: configuration.timeout) do
          connect
        end
      end

      def self.pool=(pool : ConnectionPool)
        @@pool = pool
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

      def self.configuration
        @@configuration ||= begin
          if url = ENV["DATABASE_URL"]?
            return Configuration.from(url)
          end

          path = File.join(Dir.current, "config", "database.yml")
          if File.exists?(path)
            return Configuration.from_yaml(File.read(path))
          end

          raise ConnectionError.new("Missing either 'config/database.yml' or 'DATABASE_URL' environment variable")
        end
      end
    end

    def self.active_connection?
      Connection.pool.active?
    end

    def self.connection
      Connection.pool.connection
    end

    def self.connection(&block)
      Connection.pool.connection do |conn|
        with conn yield conn
      end
    end

    def self.release_connection
      Connection.pool.release
    end
  end
end
