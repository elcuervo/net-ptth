class Net::PTTH
  OutgoingRequest = Struct.new(:req) do
    def to_s
      package = "#{req.method} #{req.path} HTTP/1.1#{Net::PTTH::CRLF}"

      req["Content-Length"] ||= req.body ? req.body.size : 0

      req.each_header do |header, value|
        header_parts = header.split("-").map(&:capitalize)
        package += "#{header_parts.join("-")}: #{value}#{Net::PTTH::CRLF}"
      end

      package += Net::PTTH::CRLF

      package += req.body if req.body
      package
    end
  end
end
