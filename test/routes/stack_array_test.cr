require "../test_helper"

class Frost::Routes::StackArrayTest < Minitest::Test
  def test_push
    ary = StackArray(Int32, 10).new
    10.times { |i| ary << i }
    10.times { |i| assert_equal i, ary[i] }

    ex = assert_raises(Exception) { ary << 1 }
    assert_match "overflow", ex.message
  end

  def test_size_and_truncate
    ary = StackArray(Int32, 10).new
    assert_equal 0, ary.size

    ary << 1
    assert_equal 1, ary.size

    ary << 1
    assert_equal 2, ary.size

    6.times { ary << 1 }
    assert_equal 8, ary.size

    ary.truncate(4)
    assert_equal 4, ary.size
  end

  def test_truncate
    ary = StackArray(Int32, 10).new
    6.times { |i| ary << i + 1 }

    ary.truncate(4)
    assert_equal 4, ary.size
    assert_equal [1, 2, 3, 4], ary.map { |i| i }

    ary.truncate(2)
    assert_equal 2, ary.size
    assert_equal [1, 2], ary.map { |i| i }

    ary.truncate(6)
    assert_equal 2, ary.size
    assert_equal [1, 2], ary.map { |i| i }

    ary.truncate(12)
    assert_equal 2, ary.size
    assert_equal [1, 2], ary.map { |i| i }

    ary.truncate(0)
    assert_equal 0, ary.size
    assert_empty ary.map { |i| i }
  end

  def test_last
    ary = StackArray(Int32, 10).new
    assert_raises(IndexError) { ary.last }

    ary << 1
    assert_equal 1, ary.last

    ary << 123
    assert_equal 123, ary.last

    ary.truncate(1)
    assert_equal 1, ary.last

    ary.truncate(0)
    assert_raises(IndexError) { ary.last }
  end

  def test_fetch
    ary = StackArray(Int32, 10).new
    assert_raises(IndexError) { ary[0] }
    ary << 1
    assert_equal 1, ary[0]
  end

  def test_each
    ary = StackArray(Int32, 8).new
    8.times { |i| ary << i }

    values = [] of Int32
    ary.each { |value| values << value }
    assert_equal [0, 1, 2, 3, 4, 5, 6, 7], values
  end

  def test_each_with_index
    ary = StackArray(Int32, 8).new
    8.times { |i| ary << i * 2 }
    ary.each_with_index { |value, i| assert_equal i * 2, value }
  end

  def test_map
    ary = StackArray(Int32, 8).new
    8.times { |i| ary << i * 2 }
    values = ary.map { |value| value * 2 }
    assert_equal [0, 4, 8, 12, 16, 20, 24, 28], values
  end
end
