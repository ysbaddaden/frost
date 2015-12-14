require "./record_test_helper"

module Frost
  class Record
    class ValidationTest < Minitest::Test
      def test_succeeded_validation
        post = Post.new(title: "title", body: "body")
        assert post.valid?

        refute post.errors.any?
        assert post.errors.empty?

        assert_empty post.errors
        assert_empty post.errors.full_messages
      end

      def test_failed_validation
        post = Post.new
        refute post.valid?

        assert post.errors.any?
        refute post.errors.empty?

        assert_equal({ title: ["Title is required"], body: ["Body is required"] }, post.errors)
        assert_equal ["Title is required", "Body is required"], post.errors.full_messages
      end

      def test_validates_on_create
        post = Post.new(title: "", body: "body")
        refute post.save
        assert post.errors.any?
        assert post.new_record?

        post.title = "title"
        assert post.save
        refute post.errors.any?
        refute post.new_record?
      end

      def test_validates_on_update
        post = Post.new(title: "title", body: "body")
        assert post.save
        refute post.errors.any?
        refute post.new_record?

        post.title = ""
        refute post.save
        assert post.errors.any?
        refute post.new_record?
      end
    end
  end
end
