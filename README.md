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
ptth.request(request) do |body, headers|
  # Handle the body of the incomming request through the reverse connection
end
```
