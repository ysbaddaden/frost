module Frost::Controller::WebSocket
  def web_socket(&block : HTTP::WebSocket -> Nil) : Nil
    unless web_socket_supported_version?
      response.headers["sec-websocket-version"] = HTTP::WebSocket::Protocol::VERSION
      return head(:upgrade_required)
    end

    unless accept_code = web_socket_accept_code?
      return head(:bad_request)
    end

    response.status = :switching_protocols
    response.headers["upgrade"] = "websocket"
    response.headers["connection"] = "Upgrade"
    response.headers["sec-websocket-accept"] = accept_code

    response.upgrade do |io|
      ws = HTTP::WebSocket.new(io, sync_close: false)
      block.call(ws)
      ws.run
    end
  end

  def web_socket_supported_version? : Bool
    request.headers["sec-websocket-version"]? == HTTP::WebSocket::Protocol::VERSION
  end

  def web_socket_accept_code? : String?
    if key = request.headers["sec-websocket-key"]?
      HTTP::WebSocket::Protocol.key_challenge(key)
    end
  end
end
