require_relative "./test_helper"
require "cuba"
require "sinatra/base"
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

describe "Using a Rack compatible app to receive requests" do
  before do
    response = Net::HTTP::Get.new("/custom_app")

    @server = Net::PTTH::TestServer.new(port: 23045, response: response)
    @ptth = Net::PTTH.new("http://localhost:23045")
    @ptth.set_debug_output = $stdout if ENV['HTTP_DEBUG']
    @request = Net::HTTP::Post.new("/reverse")

    Thread.new { @server.start }
  end

  after do
    @server.close
  end

  def check_app_compatibility(app)
    @ptth.app = app

    @ptth.async.request(@request)
    sleep 1
    @ptth.close
  end

  it "should be able to receive a Cuba app" do
    CubaApp = Class.new(Cuba) do
      define do
        on "custom_app" do
          res.write "indeeed!"
        end
      end
    end

    check_app_compatibility(CubaApp)
  end

  it "should be able to receive a sinatra app" do
    SinatraApp = Sinatra.new do
      get "/custom_app" do
        "indeeed!"
      end
    end

    check_app_compatibility(SinatraApp)
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
