require "digest/sha256"
require "./session/handler"
require "./session/store"

module Frost
  class Session
    def self.generate_sid : String
      Random::Secure.hex(16)
    end

    def self.hash_id(public_id : String) : String
      "SHA256;#{Digest::SHA256.hexdigest(public_id)}"
    end

    getter public_id : String

    def initialize(
      @public_id : String = self.class.generate_sid,
      @data : Hash(String, String) = {} of String => String,
    )
      @changed = false
    end

    def private_id : String
      self.class.hash_id(@public_id)
    end

    def []=(key : String, value : String) : String
      @changed = true
      @data[key] = value
    end

    def [](key : String) : String
      @data[key]
    end

    def []?(key : String) : String?
      @data[key]?
    end

    def delete(key : String) : String?
      @changed = true
      @data.delete(key)
    end

    def clear : Nil
      @changed = true
      @data.clear
    end

    def reset! : Nil
      @public_id = self.class.generate_sid
      @data.clear
      @changed = true
    end

    def changed? : Bool
      @changed
    end

    def to_json : String
      @data.to_json
    end
  end
end
