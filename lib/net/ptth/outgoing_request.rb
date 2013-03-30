class Net::PTTH
  class OutgoingRequest < Struct.new(:req)
    def to_s
      package = "#{req.method} #{req.path} HTTP/1.1\n"

      req["Content-Length"] ||= req.body ? req.body.size : 0

      req.each_header do |header, value|
        header_parts = header.split("-").map(&:capitalize)
        package += "#{header_parts.join("-")}: #{value}\n"
      end

      package += "\n\r#{req.body}" if req.body
      package += "\r\n\r\n"
      package
    end
  end
end
