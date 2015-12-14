require "minitest/autorun"
require "secure_random"
require "../../src/support/message_verifier"

module Frost::Support
  class MessageVerifierTest < Minitest::Test
    def key
      @key ||= SecureRandom.hex(16)
    end

    def verifier
      MessageVerifier.new(key)
    end

    def test_sign_and_verify
      message = "my special message--iv"
      signed_message = verifier.sign(message)
      assert_equal message, verifier.verify(signed_message)
    end
  end
end
