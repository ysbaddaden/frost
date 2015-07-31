require "http/response"

class HTTP::Response
  setter :status_code

  def body=(str)
    @body = str
    @headers["Content-Length"] = str.bytesize.to_s
  end
end
