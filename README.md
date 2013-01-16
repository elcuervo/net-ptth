# Net::PTTH

`Net::HTTP` compatible `PTTH` client

## You misspelled HTTP

No I don't: http://wiki.secondlife.com/wiki/Reverse_HTTP

## Installation

```bash
  gem install net-ptth
```

## Usage

```ruby
require 'net/ptth'
require 'net/http'

ptth = Net::PTTH.new("http://localhost:23045")
request = Net::HTTP::Post.new("/reverse")
ptth.request(request) do |incomming_request|
  # Handle the body of the incomming request through the reverse connection
  # This will be executed with each new request.
  # incomming_request it's a Rack::Request object
  # You can close the connection with:
  # ptth.close
end
```

## Rack compatiblity

An app can be defined to be mounted like rackup will. So you can do things like
this:

```ruby
require 'net/ptth'
require 'net/http'

ptth = Net::PTTH.new("http://localhost:23045")
ptth.app = Cuba.define do
  on "dog" do
    res.write "Hello? this is dog"
  end
end

request = Net::HTTP::Post.new("/reverse")
ptth.request(request)
```

And let the app handle the responses of the reverse connection.
Both Cuba and sinatra were tested
