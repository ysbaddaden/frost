require "../../test_helper"

class TimeTest < Minitest::Test
  private def to_tuple(time)
    time = time.to_utc
    {time.year, time.month, time.day, time.hour, time.minute, time.second, time.millisecond}
  end

  def test_parse_json
    time = Time.parse("2010-01-03T13:54:21.123Z")
    assert_equal({2010, 1, 3, 13, 54, 21, 123}, to_tuple(time))

    time = Time.parse("2010-01-03 13:54:21 +0000")
    assert_equal({2010, 1, 3, 13, 54, 21, 0}, to_tuple(time))
  end

  def test_parse_barely_valid_json
    time = Time.parse("2010-1-3T1:4:1.300Z")
    assert_equal({2010, 1, 3, 1, 4, 1, 300}, to_tuple(time))

    time = Time.parse("2010-1-3 3:5:2 +0000")
    assert_equal({2010, 1, 3, 3, 5, 2, 0}, to_tuple(time))
  end

  def test_parse_json_timezone
    time = Time.parse("2010-01-03T00:54:21.123+0100")
    assert_equal({2010, 1, 2, 23, 54, 21, 123}, to_tuple(time))

    time = Time.parse("2010-01-03 13:54:21 -0430")
    assert_equal({2010, 1, 3, 18, 24, 21, 0}, to_tuple(time))
  end

  def test_parse_iso8601
    time = Time.parse("2010-01-03T13:54:21+00:00")
    assert_equal({2010, 1, 3, 13, 54, 21, 0}, to_tuple(time))

    time = Time.parse("2010-1-3T1:5:2+00:00")
    assert_equal({2010, 1, 3, 1, 5, 2, 0}, to_tuple(time))
  end

  def test_parse_iso8601_timezone
    time = Time.parse("2010-01-03T00:54:21+01:00")
    assert_equal({2010, 1, 2, 23, 54, 21, 0}, to_tuple(time))

    time = Time.parse("2010-01-03T00:54:21-04:45")
    assert_equal({2010, 1, 3, 5, 39, 21, 0}, to_tuple(time))
  end

  def test_parse_rfc822
    time = Time.parse("Sat, 31 Oct 2015 23:45:17 +0000")
    assert_equal({2015, 10, 31, 23, 45, 17, 0}, to_tuple(time))

    time = Time.parse("Mon, 01 Jun 1970 01:02:03 +0000")
    assert_equal({1970, 6, 1, 1, 2, 3, 0}, to_tuple(time))

    time = Time.parse("Mon, 1 Jun 1970 1:2:3 +0000")
    assert_equal({1970, 6, 1, 1, 2, 3, 0}, to_tuple(time))
  end

  def test_parse_rfc822
    time = Time.parse("Sat, 01 Oct 2015 00:45:17 +0100")
    assert_equal({2015, 9, 30, 23, 45, 17, 0}, to_tuple(time))

    time = Time.parse("Mon, 01 Jun 1970 01:02:03 -0530")
    assert_equal({1970, 6, 1, 6, 32, 3, 0}, to_tuple(time))
  end

  def test_iso8601
    assert_equal "2015-10-31T10:11:12+00:00", Time.new(2015, 10, 31, 10, 11, 12).iso8601
    assert_equal "2016-01-02T03:04:05+00:00", Time.new(2016, 1, 2, 3, 4, 5).iso8601

    assert_equal("2016-01-02T03:04:05+00:00", String.build do |str|
      Time.new(2016, 1, 2, 3, 4, 5).iso8601(str)
    end)
  end

  def test_rfc822
    assert_equal "Sat, 31 Oct 2015 10:11:12 +0000", Time.new(2015, 10, 31, 10, 11, 12).rfc822
    assert_equal "Sat, 2 Jan 2016 03:04:05 +0000", Time.new(2016, 1, 2, 3, 4, 5).rfc822

    assert_equal("Sat, 2 Jan 2016 03:04:05 +0000", String.build do |str|
      Time.new(2016, 1, 2, 3, 4, 5).rfc822(str)
    end)
  end

  def test_to_json
    assert_equal "2015-10-31T11:12:13.000Z", Time.new(2015, 10, 31, 11, 12, 13, kind: Time::Kind::Utc).to_json
    assert_equal "2016-01-02T03:04:05.000Z", Time.new(2016, 1, 2, 3, 4, 5, kind: Time::Kind::Utc).to_json

    assert_equal("\"2016-01-02T03:04:05.000Z\"", String.build do |str|
      Time.new(2016, 1, 2, 3, 4, 5, kind: Time::Kind::Utc).to_json(str)
    end)
  end
end
