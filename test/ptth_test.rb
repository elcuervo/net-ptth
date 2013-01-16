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
    @request = Net::HTTP::Post.new("/reverse")

    Thread.new { @server.start }
  end

  after do
    @server.close
  end

  def check_app_compatibility(app)
    app.ptth = @ptth
    @ptth.app = app

    timeout(1) { @ptth.request(@request) }
  rescue Timeout::Error
    flunk("The reverse connection was not closed")
  end

  it "should be able to receive a Cuba app" do
    CubaApp = Class.new(Cuba) do
      class << self
        attr_accessor :ptth
      end

      define do
        on "custom_app" do
          res.write "indeeed!"
          self.class.ptth.close
        end
      end
    end

    check_app_compatibility(CubaApp)
  end

  it "should be able to receive a sinatra app" do
    SinatraApp = Sinatra.new do
      class << self
        attr_accessor :ptth
      end

      get "/custom_app" do
        self.class.ptth.close
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
