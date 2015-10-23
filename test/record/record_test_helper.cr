require "../test_helper"
require "../../src/record"
require "../../src/minitest"
require "secure_random"

ENV["DATABASE_URL"] ||= "postgres://postgres@/trail_test"

class Post < Trail::Record
  has_many :comments

  def validate
    if title.blank?
      errors.add(:title, "Title is required")
    elsif title.to_s.size >= 100
      errors.add(:title, "Title must be less than 100 characters")
    end

    if body.blank?
      errors.add(:body, "Body is required")
    end
  end
end

class Comment < Trail::Record
  belongs_to :post
end

class Minitest::Test
  fixtures "#{ __DIR__ }/../fixtures"
end
