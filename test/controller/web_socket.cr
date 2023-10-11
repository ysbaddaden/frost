require "../test_helper"
require "syn/future"

class Frost::ControllerTest < Minitest::Test
  include Frost::Controller::TestHelper

  class XController < Controller
    def socket
      if request.upgrade?("websocket")
        web_socket do |ws|
          ws.on_message do |msg|
            ws.send "echo: #{msg}"
            ws.close
          end
        end
      else
        head :ok
      end
    end
  end

  def test_upgrade_request?
    # not an upgrade
    response = call(:socket)
    assert_equal HTTP::Status::OK, response.status

    # not a websocket upgrade
    response = call(:socket, headers: HTTP::Headers{
      "upgrade" => "whatever",
      "connection" => "keep-alive, upgrade",
    })
    assert_equal HTTP::Status::OK, response.status

    # missing version
    response = call(:socket, headers: HTTP::Headers{
      "upgrade" => "websocket",
      "connection" => "keep-alive, upgrade",
    })
    assert_equal HTTP::Status::UPGRADE_REQUIRED, response.status

    # invalid version
    response = call(:socket, headers: HTTP::Headers{
      "upgrade" => "websocket",
      "connection" => "keep-alive, upgrade",
      "sec-websocket-version" => "10",
    })
    assert_equal HTTP::Status::UPGRADE_REQUIRED, response.status

    # missing key
    response = call(:socket, headers: HTTP::Headers{
      "upgrade" => "websocket",
      "connection" => "keep-alive, upgrade",
      "sec-websocket-version" => HTTP::WebSocket::Protocol::VERSION,
    })
    assert_equal HTTP::Status::BAD_REQUEST, response.status

    # finally a websocket upgrade!
    response = call(:socket, headers: HTTP::Headers{
      "upgrade" => "websocket",
      "connection" => "keep-alive, upgrade",
      "sec-websocket-version" => HTTP::WebSocket::Protocol::VERSION,
      "sec-websocket-key" => "12345",
    })
    assert_equal HTTP::Status::SWITCHING_PROTOCOLS, response.status
  end

  def test_web_socket
    address = Syn::Future(Socket::IPAddress).new

    server = HTTP::Server.new do |ctx|
      ctrl = XController.new(ctx, Frost::Routes::Params.new, "socket")
      ctrl.run_action { ctrl.socket }
    end

    spawn do
      address.set(server.bind_tcp("127.0.0.1", 0))
      server.listen
    end

    called = false

    ws = HTTP::WebSocket.new("ws://#{address.get}")
    ws.on_message do |msg|
      called = true
      assert_equal "echo: lorem ipsum", msg
    end
    ws.send("lorem ipsum")
    ws.run

    assert called
  end
end
