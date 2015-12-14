require "base64"
require "crypto/subtle"
require "openssl/hmac"
require "./slice"

module Frost
  module Support
    # Adapted from ActiveSupport::MessageVerifier
    #
    # Copyright (c) 2005-2015 David Heinemeier Hansson
    #
    # * https://github.com/rails/rails/blob/master/activesupport/lib/active_support/message_verifier.rb
    # * https://github.com/rails/rails/blob/master/activesupport/MIT-LICENSE
    class MessageVerifier
      class InvalidSignature < Exception
      end

      DEFAULT_DIGEST = :sha1

      getter :key, :digest_name

      def initialize(@key : Slice, @digest_name = DEFAULT_DIGEST)
      end

      def self.new(key : String, digest_name = DEFAULT_DIGEST)
        new(Slice.from_hexstring(key), digest_name)
      end

      def sign(message)
        data = Base64.strict_encode(message)
        "#{ data }--#{ generate(data) }"
      end

      def verify(signed_data)
        data, signature = signed_data.split("--", 2)

        if Crypto::Subtle.constant_time_compare(signature.to_slice, generate(data).to_slice)
          Base64.decode_string(data)
        else
          raise InvalidSignature.new
        end
      rescue Base64::Error
        raise InvalidSignature.new
      end

      private def generate(data)
        OpenSSL::HMAC.hexdigest(digest_name, key, data)
      end
    end
  end
end
