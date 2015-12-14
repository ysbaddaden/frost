require "./store"
require "../../support/message_encryptor"
require "../../support/message_verifier"

module Frost
  class Controller
    module Session
      class CookieStore < Store
        def read
          if cookie = request.cookies[cookie_name]?
            data = encryptor.decrypt(verifier.verify(cookie.value))
            @data = Session.unserialize(data)
          end
        end

        def save
          encrypted_data = encryptor.encrypt(Session.serialize(data))
          set_cookie(cookie_name, verifier.sign(encrypted_data))
        end

        protected def encryptor
          @@encryptor ||= Support::MessageEncryptor.new(Frost.config.secret_key)
        end

        protected def verifier
          @@verifier ||= Support::MessageVerifier.new(Frost.config.secret_key)
        end
      end
    end
  end
end
