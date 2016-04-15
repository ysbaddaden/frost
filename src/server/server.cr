require "http/server"
require "./handlers/*"
require "option_parser"

module Frost
  abstract class Server
    property host
    property port

    def initialize(@host = "localhost", @port = 9292)
    end

    def parse_cli_options
      opts.parse(ARGV)
    rescue ex : OptionParser::InvalidOption
      STDERR.puts ex.message
      STDERR.puts
      STDERR.puts "Available options:"
      STDERR.puts opts
      exit
    end

    def opts
      @opts ||= OptionParser.new.tap do |opts|
        opts.on("-b HOST", "--bind=HOST", "Bind to host (defaults to #{ host })") { |value| @host = value }
        opts.on("-p PORT", "--port=PORT", "Bind to port (defaults to #{ port })") { |value| @port = value.to_i }
        opts.on("-h", "--help", "Show this help") { puts opts; exit }
      end
    end

    def handlers
      [
        Frost::Server::LogHandler.new,
        Frost::Server::HttpsEverywhereHandler.new(308),
        Frost::Server::PublicFileHandler.new(File.join(Frost.root, "public"))
      ]
    end

    abstract def dispatcher

    def run
      server = HTTP::Server.new(host, port, handlers) do |context|
        dispatcher.call(context)
      end

      puts "Listening on http://#{ host }:#{ port }"
      server.listen
    end

    def self.run
      server = new
      server.parse_cli_options
      server.run
    end
  end
end
