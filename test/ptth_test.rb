require_relative "./test_helper"
require "cuba"
require "sinatra/base"
require "net/ptth"
require "net/ptth/test"

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
    response = Net::HTTP::Post.new("/other")
    response.body = "thing"
    @server = Net::PTTH::TestServer.new(port: 23045, response: response)

    Thread.new { @server.start }
  end

  after do
    @server.close
  end

  it "should be able to switch the incoming test request" do
    ptth = Net::PTTH.new("http://localhost:23045")
    request = Net::HTTP::Post.new("/reverse")

    ptth.app = Cuba.define do
      on "other" do
        ptth.close
      end
    end

    ptth.request(request)
  end
end
