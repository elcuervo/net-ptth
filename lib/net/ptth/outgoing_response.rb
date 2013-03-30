class Net::PTTH
  class OutgoingResponse < Struct.new(:status, :headers, :body)
    def to_s
      packet = "HTTP/1.1 #{status} OK\n"
      headers.each { |key, value| packet += "#{key}: #{value}\n" }
      packet += "\r\n"
      body.each { |chunk| packet += chunk }

      packet
    end
  end
end
