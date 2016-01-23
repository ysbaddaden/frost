require "http/server/response"

class HTTP::Server::Response
  class Cookies
    def initialize(@response)
      @cookies = {} of String => Cookie
    end

    def [](name)
      @cookies[name]
    end

    def []?(name)
      @cookies[name]?
    end

    def each
      @cookies.each { |cookie| yield cookie }
    end

    def add(cookie : Cookie)
      @cookies[cookie.name] = cookie
      @response.headers.add("Set-Cookie", cookie.to_set_cookie_header)
    end

    def <<(cookie : Cookie)
      add(cookie)
    end

    def delete(name)
      @cookies.delete(name.to_s)
      escaped_name = "#{ URI.escape(name) }="

      if headers = @response.headers.get?("Set-Cookie")
        headers.reject!(&.starts_with?(escaped_name))
      end
    end
  end

  def cookies
    @cookies ||= Cookies.new(self)
  end

  def body
    @body || ""
  end

  def body?
    @body
  end

  def body=(str)
    self.content_length = str.bytesize
    @body = str
    #self << str
    #flush
  end

  def flush
    if (body = @body) && !@flushed_body
      self << body
      @flushed_body = true
    end
    @output.flush
  end

  def close
    flush
    @output.close
  end
end
