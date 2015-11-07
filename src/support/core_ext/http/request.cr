require "http/request"

class HTTP::Request
  setter :method

  def path
    uri.path || "/"
  end
end
