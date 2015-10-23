require "minitest/autorun"
require "../../src/support/message_encryptor"

module Trail::Support
  class MessageEncryptorTest < Minitest::Test
    def key
      @key ||= begin
                 cipher = OpenSSL::Cipher.new(MessageEncryptor::DEFAULT_CIPHER)
                 cipher.random_key.hexstring
               end
    end

    def encryptor
      MessageEncryptor.new(key)
    end

    def test_encrypt_and_decrypt
      message = "my secret message"
      encrypted_message = encryptor.encrypt(message)
      decrypted_message = encryptor.decrypt(encrypted_message)
      assert_equal message, decrypted_message
    end

    def test_invalid_key
      ex = assert_raises(ArgumentError) do
        MessageEncryptor.new("abcdef").encrypt("secret")
      end
      assert_match /key length/, ex.message
    end

    def test_invalid_iv
      message, _ = encryptor.encrypt("secret").split("--")
      assert_raises(MessageEncryptor::InvalidMessage) do
        encryptor.decrypt("#{ message }--£123456789abcdef012345")
      end

      assert_raises(MessageEncryptor::InvalidMessage) do
        encryptor.decrypt("#{ message }--0123456789abcdef012345")
      end
    end

    def test_invalid_message
      _, iv = encryptor.encrypt("secret").split("--")

      assert_raises(MessageEncryptor::InvalidMessage) do
        encryptor.decrypt("£0928109280192808--#{ iv }")
      end

      assert_raises(MessageEncryptor::InvalidMessage) do
        encryptor.decrypt("0928109280192808--#{ iv }")
      end
    end
  end
end
