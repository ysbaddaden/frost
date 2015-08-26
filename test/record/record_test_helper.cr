require "../test_helper"
require "../../src/record"

ENV["DATABASE_URL"] ||= "postgres://postgres@/trail_test"

class Post < Trail::Record
  def validate
    if title.blank?
      errors.add(:title, "Title is required")
    elsif title.to_s.length >= 100
      errors.add(:title, "Title must be less than 100 characters")
    end

    if body.blank?
      errors.add(:body, "Body is required")
    end
  end
end

class Comment < Trail::Record
end
