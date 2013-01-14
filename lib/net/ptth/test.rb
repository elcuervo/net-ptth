require "net/http"

module Net
  class PTTH
    class TestServer
      # Public: Initialize the PTTH test server
      #
      #   port: the port in which the server will listen
      #
      def initialize(configuration = {})
        port = configuration.fetch(:port, 23045)
        response = Net::HTTP::Post.new("/reverse")
        response.body = "reversed"

        @response = configuration.fetch(:response, response)
        @server = TCPServer.new(port)
      end

      # Public: Starts the test server
      #
      def start
        loop do
          client = @server.accept

          switch_protocols = <<-EOS.gsub(/^\s+/, '')
            HTTP/1.1 101 Switching Protocols
            Date: Mon, 14 Jan 2013 11:54:24 GMT
            Upgrade: PTTH/1.0
            Connection: Upgrade


          EOS

          post_response  = "#{@response.method} #{@response.path} HTTP/1.1\n"
          post_response += "Content-Length: #{@response.body.length}\n" if @response.body
          post_response += "Accept: */*\n"
          post_response += "\n"
          post_response += @response.body if @response.body

          client.puts switch_protocols
          sleep 0.5
          client.puts post_response
        end
      end

      # Public: Stops the current server
      #
      def close
        @server.close
      end
    end
  end
end
