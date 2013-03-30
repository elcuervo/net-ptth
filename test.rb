$: << File.expand_path("lib")

require "net/ptth"
require "net/http"
require "cuba"

puts "Connecting"
ptth = Net::PTTH.new("http://127.0.0.1:7000")
ptth.set_debug_output = $stdout
ptth.app = Cuba.define do
  on default do
    #puts req.body.read
  end
end

puts "Building request"
request = Net::HTTP::Post.new("/reverse")
request["Connection"] = "Upgrade"
request["Upgrade"] = "PTTH/1.0"

puts "Making request"
something = ptth.request(request)
puts "something"
