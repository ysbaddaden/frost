require "./test_helper"

class Frost::SessionTest < Minitest::Test
  def test_generate_sid
    sid = Session.generate_sid
    assert_equal 32, sid.bytesize
  end

  def test_hash_id
    sid = "499f3e7059280afa38e2c211ae8aab62"
    assert_equal "SHA256;b36b844fbb18c46a9edf039271c760b3b89294e123ed061ac1de8476046ec867", Session.hash_id(sid)
  end

  def test_new_session
    session = Session.new
    assert_equal 32, session.public_id.bytesize
    assert_nil session["user_id"]?
  end

  def test_existing_session
    assert_equal "e58ffd6aa48b2d102583562e458c9423", session.public_id
    assert_equal "12345", session["user_id"]
    assert_nil session["unknown"]?
  end

  def test_accessors
    assert_equal "12345", session["user_id"]
    assert_equal "1", session["dnt"]
    assert_raises(KeyError) { session["what"] }

    assert_equal "12345", session["user_id"]?
    assert_equal "1", session["dnt"]?
    assert_nil session["what"]?
  end

  def test_delete
    session.delete("user_id")
    assert_nil session["user_id"]?
    assert session["dnt"]
  end

  def test_clear
    session.clear
    assert_nil session["user_id"]?
    assert_nil session["dnt"]?
  end

  def test_reset!
    sid = session.public_id
    session.reset!
    refute_equal sid, session.public_id
    assert_nil session["user_id"]?
    assert_nil session["dnt"]?
  end

  private def session
    @session ||= Session.new("e58ffd6aa48b2d102583562e458c9423", data: {
      "user_id" => "12345",
      "dnt" => "1",
    })
  end
end
