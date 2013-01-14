require_relative "./test_helper"
require "net/ptth"

describe "PTTH connection" do
  before do
    Thread.new do
      @server = TCPServer.new(23045)

      loop do
        client = @server.accept

        switch_protocols = <<-EOS.gsub(/^\s+/, '')
          HTTP/1.1 101 Switching Protocols
          Date: Mon, 14 Jan 2013 11:54:24 GMT
          Upgrade: PTTH/1.0
          Connection: Upgrade


        EOS

        post_response  = "POST /reversed HTTP/1.1\n"
        post_response += "Content-Length: 8\n"
        post_response += "Accept: */*\n"
        post_response += "\n"
        post_response += "reversed"

        client.puts switch_protocols
        sleep 0.5
        client.puts post_response
      end
    end
  end

  after do
    @server.close
  end

  it "should stablish a reverse connection" do
    ptth = Net::PTTH.new("http://localhost:23045")
    request = Net::HTTP::Post.new("/reverse")

    ptth.request(request) do |body|
      assert_equal "reversed", body
      ptth.close
    end
  end
end
