require_relative "./test_helper"
require "net/ptth"
require "net/ptth/test"

describe "PTTH connection" do
  before do
    @server = Net::PTTH::TestServer.new(port: 23045)
    Thread.new { @server.start }
  end

  after do
    @server.close
  end

  it "should stablish a reverse connection" do
    ptth = Net::PTTH.new("http://localhost:23045")
    request = Net::HTTP::Post.new("/reverse")

    ptth.request(request) do |incoming_request|
      assert_equal "reversed", incoming_request.body.read
      ptth.close
    end
  end
end

describe "PTTH Test server" do
  before do
    response = Net::HTTP::Get.new("/other")
    @server = Net::PTTH::TestServer.new(port: 23045, response: response)

    Thread.new { @server.start }
  end

  after do
    @server.close
  end

  it "should be able to switch the incoming test request" do
    ptth = Net::PTTH.new("http://localhost:23045")
    request = Net::HTTP::Post.new("/reverse")

    ptth.request(request) do |incoming_request|
      assert_equal "/other", incoming_request.path
      ptth.close
    end
  end
end
