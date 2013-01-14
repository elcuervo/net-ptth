require "uri"
require "rack"
require "net/http"
require "http-parser"
require "celluloid/io"

class Net::PTTH
  include Celluloid::IO

  # Public: Constructor
  #
  #   address: The address where the connection will be made
  #   port: An optional port if the port is different from the one in the
  #         address
  #
  def initialize(address, port = 80)
    info = URI.parse(address)

    @host, @port = info.host, info.port || port
    @parser = HTTP::Parser.new
    @debug_output = StringIO.new
  end

  # Public: Mimics Net::HTTP set_debug_output
  #
  #   output: A StringIO compatible object
  #
  def set_debug_output=(output)
    @debug_output = output
  end

  # Public: Closes de current connection
  #
  def close
    log "[Closing connection]"
    @socket.close if @socket
  end

  # Public: Generates a request based on a Net::HTTP object and yields a
  #         response
  #
  #   req: The request to be executed
  #   &block: That will handle the response
  #
  def request(req, &block)
    @socket ||= TCPSocket.new(@host, @port)

    log "[Connecting...]"

    packet = build(req)

    log "[Writting packet]"
    log packet

    @socket.write(packet)

    response = @socket.readpartial(1024)
    log "[Reading response]"
    log response
    @parser << response

    if @parser.http_status == 101
      log "[Switching protocols]"

      while res = @socket.readpartial(1024)
        log "[Incoming response]"
        log res

        headers = {}
        path = nil
        body = ""

        @parser.reset
        parse_headers(headers)

        @parser.on_url { |url| path = url }
        @parser.on_body { |response_body| body = StringIO.new(response_body) }
        @parser.on_message_complete do
          env = {
            "PATH_INFO" => path,
            "rack.input" => body,
            "REQUEST_METHOD" => @parser.http_method,
          }

          env.tap do |h|
            h["CONTENT_LENGTH"] = body.length if body
          end

          request = Rack::Request.new(env)
          headers.each do |header, value|
            request[header] = value
          end

          block.call(request)
        end

        @parser << res
      end
    end
  rescue IOError => e
  rescue EOFError => e
    @socket.close
  end

  private

  # Private: Logs a debug message
  #
  #   message: The string to be logged
  #
  def log(message)
    @debug_output << message + "\n"
  end

  # Private: Parses the incoming request headers and adds the information to a
  #          given object
  #
  #   headers: The object in which the headers will be added
  #
  def parse_headers(headers)
    raw_headers = []
    add_header = proc { |header| raw_headers << header }

    @parser.on_header_field &add_header
    @parser.on_header_value &add_header
    @parser.on_headers_complete do
      raw_headers.each_slice(2) do |key, value|
        headers[key] = value
      end
    end
  end

  # Private: Builds a reversed request
  #
  #   req: The request to be build
  #
  def build(req)
    req["Upgrade"]    ||= "PTTH/1.0"
    req["Connection"] ||= "Upgrade"

    package  = "#{req.method} #{req.path} HTTP/1.1\n"
    req.each_header do |header, value|
      package += "#{header.split("-").map(&:capitalize).join("-")}: #{value}\n"
    end

    package += "\n\r#{req.body}"
    package += "\n\r\n\r"
  end
end
