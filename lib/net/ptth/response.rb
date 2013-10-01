class Net::PTTH
  Response = Struct.new(:method, :status, :headers, :body) do
    def [](key)
      headers[key]
    end
  end
end
