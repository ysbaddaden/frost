require "timecop"

class Frost::Session
  def_equals @public_id, @data
end

module Frost::Session::StoreTestSuite
  macro included
    def test_session_lifetime
      s1 = Session.new(data: { "user_id" => "1" })
      s2 = Session.new(data: { "key" => "value" })

      assert_nil store.find_session(s1.public_id)
      assert_nil store.find_session(s2.public_id)

      store.write_session(s1)
      assert_equal s1, store.find_session(s1.public_id)
      assert_nil store.find_session(s2.public_id)

      store.write_session(s2)
      assert_equal s1, store.find_session(s1.public_id)
      assert_equal s2, store.find_session(s2.public_id)

      store.delete_session(s1)
      assert_nil store.find_session(s1.public_id)
      assert_equal s2, store.find_session(s2.public_id)

      store.delete_session(s2)
      assert_nil store.find_session(s1.public_id)
      assert_nil store.find_session(s2.public_id)
    end

    def test_find_expired_session_returns_nil
      session = Session.new
      store.write_session(session)

      Timecop.travel(1.day.from_now) do
        assert_nil store.find_session(session.public_id)
      end
    end

    def test_extend_session
      s1 = Session.new
      store.write_session(s1)

      s2 = Session.new
      store.write_session(s2)

      Timecop.travel(10.minutes.from_now) do
        store.extend_session(s1)
      end

      Timecop.travel(25.minutes.from_now) do
        assert_equal s1, store.find_session(s1.public_id)
        assert_nil store.find_session(s2.public_id)
      end

      Timecop.travel(31.minutes.from_now) do
        assert_nil store.find_session(s1.public_id)
        assert_nil store.find_session(s2.public_id)
      end
    end

    def test_overwrite_session
      sid = Session.generate_sid
      s1 = Session.new(sid, { "key" => "value" })
      s2 = Session.new(sid, { "user_id" => "2" })

      store.write_session(s1)
      store.write_session(s2)

      assert session = store.find_session(sid)
      assert_equal s2, session
    end

    def test_delete_unknown_session_fails_silently
      store.delete_session(Session.new)
    end
  end

  private abstract def store(expire_after = 20.minutes)
end
