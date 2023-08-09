require "../test_helper"
require "../../src/session/memory_store"
require "./store_test_suite"

class Frost::Session::MemoryStoreTest < Minitest::Test
  include StoreTestSuite

  def test_call_removes_expired_sessions
    store.write_session(s1 = Session.new)

    Timecop.travel(10.minutes.from_now) do
      store.write_session(s2 = Session.new)

      Timecop.travel(15.minutes.from_now) do
        store.call(Time.utc)

        assert_nil store.find_session(s1.public_id)
        assert_equal s2, store.find_session(s2.public_id)

        Timecop.travel(10.minutes.from_now) do
          store.call(Time.utc)
          assert_nil store.find_session(s2.public_id)
        end
      end
    end
  end

  private def store(expire_after = 20.minutes)
    @store ||= MemoryStore.new(expire_after, schedule_clean_cron: nil)
  end
end
