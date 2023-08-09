require "./cookie_jar"

class Frost::Integration::Session
  @request : HTTP::Request?
  @response : HTTP::Client::Response?
  @cookie_jar = CookieJar.new

  def initialize(@request_processor : HTTP::Server::RequestProcessor)
  end

  # TODO: encode body params (multipart)
  # TODO: encode body params (json)
  def process(
    http_method : String,
    resource : String,
    headers : HTTP::Headers? = nil,
    params = nil,
  ) : Nil
    input, output = IO::Memory.new, IO::Memory.new

    # generate request
    @request = request = HTTP::Request.new(http_method.upcase, resource, headers)
    @cookie_jar.fill(request)
    if params
      request.headers["content-type"] = "application/x-www-form-urlencoded"
      request.body = URI::Params.encode(params)
    end
    request.to_io(input)

    # process request
    @request_processor.process(input.rewind, output)

    # parse response
    @response = response = HTTP::Client::Response.from_io(output.rewind)
    @cookie_jar.add(response)
  end

  def request : HTTP::Request
    @request || raise "ERROR: please issue a request first"
  end

  def response : HTTP::Client::Response
    @response || raise "ERROR: please issue a request first"
  end

  def reset! : Nil
    @request = @response = nil
    @cookie_jar.clear
  end
end
