require "celluloid/io"

class Net::PTTH
  Socket = Struct.new(:host, :port) do
    include Celluloid::IO

    def read(bytes = 4096*10)
      raw_socket.readpartial(bytes)
    end

    def write(data)
      raw_socket.write(data)
    end

    def close
      raw_socket.close
    end

    def open?
      !raw_socket.closed?
    end

    def raw_socket
      @_socket ||= TCPSocket.new(host, port)
    end
  end
end
