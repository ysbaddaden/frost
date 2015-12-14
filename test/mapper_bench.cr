require "./routing/mapper_test"
require "benchmark"
require "secure_random"

module SecureRandom
  def self.uuid
    bytes = random_bytes(16)
    {
      bytes[0, 4].hexstring,
      bytes[4, 2].hexstring,
      bytes[6, 2].hexstring,
      bytes[8, 2].hexstring,
      bytes[10, 2].hexstring,
      bytes[12, 4].hexstring,
    }.join("-")
  end
end

N = 100_000

module Frost::Routing
  class MapperBench < Minitest::Test
    def test_match
      root = HTTP::Request.new("GET", "/")
      post = HTTP::Request.new("GET", "/posts/1")
      post_format = HTTP::Request.new("GET", "/posts/1.json")
      post_uuid = HTTP::Request.new("GET", "/posts/#{ SecureRandom.uuid }")
      post_uuid_format = HTTP::Request.new("GET", "/posts/#{ SecureRandom.uuid }.html")
      post_comment = HTTP::Request.new("GET", "/posts/1/comments/2")
      post_comment_uuid = HTTP::Request.new("GET", "/posts/#{ SecureRandom.uuid }/comments/#{ SecureRandom.uuid }")

      Benchmark.bm do |x|
        x.report("GET /") { N.times { app.dispatch(root) } }
        x.report("GET /posts/:id") { N.times { app.dispatch(post) } }
        x.report("GET /posts/:id.:format") { N.times { app.dispatch(post_format) } }
        x.report("GET /posts/:uuid") { N.times { app.dispatch(post_uuid) } }
        x.report("GET /posts/:uuid.:format") { N.times { app.dispatch(post_uuid_format) } }
        x.report("GET /posts/:uuid/comments/:uuid") { N.times { app.dispatch(post_comment) } }
        x.report("GET /posts/:uuid/comments/:uuid.:format") { N.times { app.dispatch(post_comment_uuid) } }
      end
    end

    def app
      @app ||= MapperTest::App::Dispatcher.new
    end
  end
end if ENV["BENCH"]?
