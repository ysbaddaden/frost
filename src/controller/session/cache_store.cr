#module Trail
#  class Controller
#    module Session
#      class CacheStore < Store
#        def read
#          if str = Session.cache.fetch(session_id, nil)
#            @data = Session.unserialize(str)
#          end
#        end
#
#        def save
#          #unless request.cookies[cookie_name]?
#            set_cookie(cookie_name, session_id)
#          #end
#
#          Session.cache.save(
#            cookie_name,
#            Session.serialize(data),
#            expires_in: options[:expire_after]
#          )
#        end
#
#        def destroy
#          Session.cache.delete(cache_key)
#          super
#        end
#
#        private def cache_key
#          "session:#{ session_id }"
#        end
#      end
#    end
#  end
#end
