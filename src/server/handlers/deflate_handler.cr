require "http/server"

class Zlib::Deflate
  def close
    input = @input

    if input.responds_to?(:close)
      input.close
    end
  end
end

class HTTP::Response
  def body_io=(@body_io)
    @body = nil
    headers.delete("Content-length")
  end
end

class HTTP::DeflateHandler < HTTP::Handler
  def call(request)
    response = call_next(request)

    if should_deflate?(request, response)
      io = if response.body?
             MemoryIO.new(response.body)
           else
             response.body_io
           end
      response.body_io = Zlib::Deflate.new(io)
      response.headers["Content-Encoding"] = "deflate"
    end

    response
  end
end
