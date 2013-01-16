require "uri"
require "rack"
require "net/http"
require "http-parser"
require "celluloid/io"

class Net::PTTH
  class Request
    attr_accessor :path, :body, :headers

    def initialize(path = "", body = "", headers = {})
      @path, @body, @headers = path, body, headers
    end
  end

  include Celluloid::IO

  attr_accessor :app

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

        request = Request.new
        build_request(request)

        @parser.on_message_complete do
          env = build_env(request)
          callbacks(env, &block)
        end

        @parser << res
      end
    end
  rescue IOError => e
  rescue EOFError => e
    @socket.close
  end

  private

  # Private: Executes the app and/or block callbacks
  #
  #   env: The Rack compatible env
  #   &block: From the request
  #
  def callbacks(env, &block)
    case
    when app then app.call(env)
    when block
      request = Rack::Request.new(env)
      block.call(request)
    else
      close
    end
  end

  # Private: Builds a Rack compatible env from a PTTH::Request
  #
  #   request: A PTTH parsed request
  #
  def build_env(request)
    env = {
      "PATH_INFO" => request.path,
      "SCRIPT_NAME" => "",
      "rack.input" => request.body,
      "REQUEST_METHOD" => @parser.http_method,
    }

    env.tap do |h|
      h["CONTENT_LENGTH"] = request.body.length if request.body
    end

    env.merge!(request.headers) if request.headers
  end


  # Private: Builds a PTTH::Request from the parsed input
  #
  #   request: The object where the parsed content will be placed
  #
  def build_request(request)
    @parser.reset
    parse_headers(request.headers)

    @parser.on_url { |url| request.path = url }
    @parser.on_body do |response_body|
      request.body = StringIO.new(response_body)
    end
  end


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
        header_name = key.
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          upcase

        headers["HTTP_" + header_name] = value
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
