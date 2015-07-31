require "../test_helper"
require "../../src/record"

ENV["DATABASE_URL"] ||= "postgres://postgres@/trail_test"

class Post < Trail::Record
end

class Comment < Trail::Record
end
