require "../test_helper"
require "../../src/session/memory_store"
require "./store_test_suite"

class Frost::Session::MemoryStoreTest < Minitest::Test
  include StoreTestSuite

  def test_call_removes_expired_sessions_only
    store.write_session(s1 = Session.new)

    Timecop.travel(10.minutes.from_now) do
      store.write_session(s2 = Session.new)

      Timecop.travel(15.minutes.from_now) do
        store.call(Time.utc)

        assert_nil store.find_session(s1.id)
        assert_equal s2, store.find_session(s2.id)

        Timecop.travel(10.minutes.from_now) do
          store.call(Time.utc)
          assert_nil store.find_session(s2.id)
        end
      end
    end
  end

  private def store
    @store ||= MemoryStore.new(schedule_clean_cron: nil)
  end
end
