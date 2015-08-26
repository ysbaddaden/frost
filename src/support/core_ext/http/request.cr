require "http/request"
require "cgi"

class HTTP::Request
  setter :method

  # FIXME: work around URI parse bugs: it won't parse escaped chars (eg: %20, %3A) nor spaces
  def uri
    URI.parse(CGI.unescape(@path).gsub(' ', '+'))
  end
end
