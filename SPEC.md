host = "http://127.0.0.1:7000"
ptth = Net::PTTH.new(host)

request = Net::HTTP::Post.new("/reverse")
ptth.app = Cuba
response = ptth.request(request)
