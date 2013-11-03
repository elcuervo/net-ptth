require "celluloid/io"

class Net::PTTH
  SocketError = Class.new(StandardError)

  Socket = Struct.new(:host, :port) do
    include Celluloid::IO

    def read(bytes = 4096*10)
      raw_socket.readpartial(bytes)
    end

    def write(data)
      retry_count = 3
      begin
        raw_socket.write(data)
      rescue Errno::EPIPE => e
        close unless open?

        retry_count -= 1
        if retry_count > 0
          retry
        else
          raise SocketError.new("Couldn't reconnect! Errno::EPIPE")
        end
      end
    end

    def close
      close_socket
    rescue IOError => e
      # I'm already closed
    end

    def open?
      !raw_socket.closed?
    end

    private

    def close_socket
      @_socket = nil
      raw_socket.close
    end

    def raw_socket
      @_socket ||= TCPSocket.new(host, port)
    end
  end
end
