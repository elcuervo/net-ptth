$: << File.expand_path("lib")

require "net/ptth"
require "net/http"
require "cuba"

puts "Connecting"
ptth = Net::PTTH.new("http://192.168.1.12:7000", keep_alive: true)
ptth.set_debug_output = $stdout
ptth.app = Cuba.define do
  on default do
    puts req.body.read
  end
end

puts "Building request"
request = Net::HTTP::Post.new("/play")
request.body = "Content-Location: http://trailers.apple.com/movies/marvel/ironman3/ironman3-tlr1-m4mb0_h1080p.mov\n"
request.body += "Start-Position: 0\n\n"

request["Content-Type"] = "text/parameters"
request["User-Agent"] = "MediaControl/1.0"

puts "Making request"
something = ptth.async.request(request)
sleep(5) && ptth.close
