require "../test_helper"
require "../../src/support/core_ext/**"

module Frost::Support
  class StringTest < Minitest::Test
    class Test
    end

    def test_blank?
      assert nil.blank?

      assert false.blank?
      refute true.blank?

      assert "".blank?
      assert " \n\t ".blank?
      refute "str".blank?

      refute Test.new.blank?
    end

    def test_present?
      refute nil.present?

      refute false.present?
      assert true.present?

      refute "".present?
      refute " \n\t ".present?
      assert "str".present?

      assert Test.new.present?
    end

    def test_presence
      assert_nil nil.presence
      assert_nil false.presence
      assert_equal true, true.presence

      assert_nil "".presence
      assert_nil " \n\t ".presence

      str = "str"
      assert_same str, str.presence

      test = Test.new
      assert_same test, test.presence
    end
  end
end
