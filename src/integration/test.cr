require "http/server"
require "./assertions"
require "./test_requests"
require "./session"

class Frost::Integration::Test < Minitest::Test
  include TestRequests
  include Assertions

  def self.middlewares : Array(HTTP::Handler)
    [Frost::Routes.handler]
  end

  @@request_processor =
    HTTP::Server::RequestProcessor.new(HTTP::Server.build_middleware(middlewares))

  def default_session : Session
    @default_session ||= Session.new(@@request_processor)
  end

  # :nodoc:
  private def default_session=(@default_session : Session?)
  end

  def process(http_method : String, resource : String, **options) : Nil
    default_session.process(http_method, resource, **options)
    @html_document = nil
  end

  def response : HTTP::Client::Response
    default_session.response
  end

  def reset! : Nil
    default_session.reset!
    @html_document = nil
  end

  def open_session(&) : Nil
    copy = dup
    copy.reset!
    yield copy
  end

  def dup : self
    copy = super

    if session = @default_session
      copy.default_session = session.dup
    end

    copy
  end
end
