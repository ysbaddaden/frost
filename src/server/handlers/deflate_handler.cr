require "http/server"
require "http/client/response"

abstract class Frost::Server
  class DeflateHandler < HTTP::DeflateHandler
    DEFAULT_DEFLATE_TYPES = %w(text/html text/plain text/xml text/css text/javascript application/javascript application/json)

    property :deflate_types

    def initialize(@deflate_types = DEFAULT_DEFLATE_TYPES)
    end

    def call(context)
      super if deflate?(context.response)
    end

    def deflate?(response)
      return false unless HTTP::Client::Response.mandatory_body?(response.status_code)
      return false if response.headers["Cache-Control"]? =~ /\bno-transform\b/
      return false unless content_type = response.headers["Content-Type"]?
      deflate_types.includes?(content_type)
    end
  end
end
