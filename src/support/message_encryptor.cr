require "base64"
require "openssl/cipher"
require "secure_random"
require "./slice"

module Frost
  module Support
    # Adapted from ActiveSupport::MessageEncryptor
    #
    # Copyright (c) 2005-2015 David Heinemeier Hansson
    #
    # * https://github.com/rails/rails/blob/master/activesupport/lib/active_support/message_encryptor.rb
    # * https://github.com/rails/rails/blob/master/activesupport/MIT-LICENSE
    class MessageEncryptor
      class InvalidMessage < Exception
      end

      DEFAULT_CIPHER = "aes-256-cbc"

      getter :key, :cipher_name

      def initialize(@key : Slice, @cipher_name = DEFAULT_CIPHER)
      end

      def self.new(key : String, cipher_name = DEFAULT_CIPHER)
        new(Slice.from_hexstring(key), cipher_name)
      end

      def encrypt(message)
        cipher = OpenSSL::Cipher.new(cipher_name)
        cipher.encrypt
        cipher.key = @key
        iv = cipher.random_iv

        secret = MemoryIO.new
        secret.write(cipher.update(message))
        secret.write(cipher.final)

        "#{ Base64.strict_encode(secret) }--#{ Base64.strict_encode(iv) }"
      end

      def decrypt(encrypted_data)
        secret, iv = encrypted_data.split("--", 2)

        cipher = OpenSSL::Cipher.new(cipher_name)
        cipher.decrypt
        cipher.key = @key
        cipher.iv = Base64.decode(iv)

        message = MemoryIO.new
        message.write(cipher.update(Base64.decode(secret)))
        message.write(cipher.final)

        message.to_s
      rescue Base64::Error | OpenSSL::Cipher::Error
        raise InvalidMessage.new
      end
    end
  end
end
