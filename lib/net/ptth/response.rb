class Net::PTTH
  class Response < Struct.new(:method, :status, :headers, :body)
    def [](key)
      headers[key]
    end
  end
end
