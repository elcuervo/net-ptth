require "uri"
require "net/http"
require "logger"

require "net/ptth/socket"
require "net/ptth/parser"
require "net/ptth/response"
require "net/ptth/incoming_request"
require "net/ptth/outgoing_response"
require "net/ptth/outgoing_request"

# Public: PTTH constructor.
#   Attempts to mimic HTTP when applicable
#
class Net::PTTH
  include Celluloid

  attr_accessor :app

  CRLF = "\r\n".freeze

  # Public: Constructor
  #
  #   address: The address where the connection will be made
  #   port: An optional port if the port is different from the one in the
  #         address
  #
  def initialize(address, options = {})
    info = URI.parse(address)

    @host, @port = info.host, info.port || options.fetch(:port, 80)
    @keep_alive = options.fetch(:keep_alive, false)
    self.set_debug_output = StringIO.new
  end

  # Public: Mimics Net::HTTP set_debug_output
  #
  #   output: A StringIO compatible object
  #
  def set_debug_output=(output)
    @debug_output = output

    Celluloid.logger = if output.respond_to?(:debug)
                         output
                       else
                         ::Logger.new(output)
                       end
  end

  # Public: Closes de current connection
  #
  def close
    @keep_alive = false
    socket.close if socket.open?
    @_socket = nil
  end

  # Public: Access to the PTTH::Socket
  #
  def socket
    @_socket ||= Net::PTTH::Socket.new(@host, @port)
  end

  # Public: Access to the PTTH::Parser
  #
  def parser
    @_parser ||= Net::PTTH::Parser.new
  end

  # Public: Generates a request based on a Net::HTTP object and yields a
  #         response
  #
  #   req: The request to be executed
  #
  def request(req)
    outgoing = Net::PTTH::OutgoingRequest.new(req)
    packet = outgoing.to_s
    socket.write(packet)

    parser.reset
    response = ""
    while !parser.finished?
      buffer = socket.read
      debug "= #{buffer}"

      response << buffer
      parser   << buffer
    end

    debug "* Initial Response: #{response}"

    if parser.upgrade?
      debug "* Upgrade response"
      debug "* Reading socket"
      parser.reset

      while socket.open?
        response = ""
        parser.reset

        buffer = socket.read
        response << buffer
        parser << buffer

        if parser.finished?
          parser.body = buffer.split(CRLF*2).last
        end

        incoming = Net::PTTH::IncomingRequest.new(
          parser.http_method,
          parser.url,
          parser.headers,
          parser.body
        )

        env = incoming.to_env
        outgoing_response = Net::PTTH::OutgoingResponse.new(*app.call(env))
        socket.write(outgoing_response.to_s)
      end
    else
      debug "* Simple request"

      if parser.finished?
        parser.body = buffer.split(CRLF*2).last
      end

      response = Net::PTTH::Response.new(
        parser.http_method,
        parser.status_code,
        parser.headers,
        parser.body
      )

      keep_connection_active if keep_alive?(response)

      response
    end

  rescue IOError => e
  rescue EOFError => e
    close
  end

  private

  def keep_alive?(response)
    response.status == 200 && @keep_alive
  end

  def keep_connection_active
    after(1) do
      while @keep_alive do
        # All you need is love. Something to keep alive the connection of that
        # given socket
        socket.write("<3") if socket.open?
        sleep 1
      end
    end
  end

  # Private: outputs debug information
  #   string: The string to be logged
  #
  def debug(string)
    return unless @debug_output
    @debug_output << string + "\n"
  end
end
