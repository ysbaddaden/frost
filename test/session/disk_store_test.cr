require "../test_helper"
require "../../src/session/disk_store"
require "./store_test_suite"
require "file_utils"

class Frost::Session::DiskStoreTest < Minitest::Test
  include StoreTestSuite

  @path : String?

  def teardown
    if path = @path
      FileUtils.rm_r(path)
    end
  end

  def test_call_removes_expired_sessions
    store = store(expire_after: 20.milliseconds)
    store.write_session(s1 = Session.new)

    sleep 10.milliseconds
    store.write_session(s2 = Session.new)

    sleep 10.milliseconds
    store.call(Time.utc)

    assert_nil store.find_session(s1.public_id)
    assert_equal s2, store.find_session(s2.public_id)

    sleep 10.milliseconds
    store.call(Time.utc)
    assert_nil store.find_session(s2.public_id)
  end

  private def store(expire_after = 20.minutes)
    @store ||= begin
                 @path = path = File.expand_path("../../tmp/session/#{Random::DEFAULT.hex(32)}", __DIR__)
                 Dir.mkdir_p(path)
                 DiskStore.new(path, expire_after, schedule_clean_cron: nil)
               end
  end
end
