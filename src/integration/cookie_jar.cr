struct Frost::Integration::CookieJar
  include Enumerable(HTTP::Cookie)

  def initialize(@cookies = HTTP::Cookies.new)
  end

  # Adds cookies from `response` to the jar. Replaces existing cookies.
  def add(response : HTTP::Client::Response) : Nil
    add(response.cookies) if response.headers["set-cookie"]?
  end

  # Adds cookies to the jar. Replaces existing cookies.
  def add(cookies : HTTP::Cookies)
    cookies.each { |cookie| add(cookie) }
  end

  # Adds a cookie to the jar. Replaces an existing cookie.
  def add(cookie : HTTP::Cookie)
    if cookie.expired?
      @cookies.delete(cookie.name)
    else
      @cookies << cookie
    end
  end

  # Adds cookies from to the jar to `request`. Skips expired cookies.
  def fill(request : HTTP::Request)
    @cookies.each { |cookie| @cookies.delete(cookie.name) if cookie.expired? }
    @cookies.add_request_headers(request.headers)
  end

  # Iterates non expired cookies from the jar.
  def each(& : HTTP::Cookie ->) : Nil
    @cookies.each do |cookie|
      if cookie.expired?
        @cookies.delete(cookie)
      else
        yield cookie
      end
    end
  end

  # Removes all cookies from the jar.
  def clear : Nil
    @cookies.clear
  end
end
