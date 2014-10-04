require 'eventmachine'
require 'em-websocket'
require 'evma_httpserver'
require 'json'

class Http2WsTransport < EM::Connection
  include EM::HttpServer
  CLIENTS = {}

  def post_init
    super
    no_environment_strings
  end

  def process_http_request
    data = JSON.parse(@http_post_content)
    clients = data["clients"]
    message = data["message"].to_json

    broadcast_message clients, message

    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    response.content = 'OK'
    response.send_response
  end

  def broadcast_message(clients, message)
    clients.each do |client|
      CLIENTS[client].send message if CLIENTS[client]
    end
  end

end

EM.run {
  EM.start_server 'localhost', 8081, Http2WsTransport
  p "Transport started"

  EM::WebSocket.run(:host => "0.0.0.0", :port => 9292) do |ws|
    ws.onopen { |handshake|
      Http2WsTransport::CLIENTS[handshake.path[1..-1]] = ws
    }

    ws.onclose { puts "Connection closed" }

    # TODO implement messaging from ws to http
    # ws.onmessage { |msg|
    # }
  end
}
