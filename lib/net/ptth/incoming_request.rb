class Net::PTTH
  IncomingRequest = Struct.new(:method, :path, :headers, :body) do
    def to_env
      env = {
        "PATH_INFO" => path,
        "SCRIPT_NAME" => "",
        "rack.input" => StringIO.new(body || ""),
        "REQUEST_METHOD" => method,
      }

      env.tap { |h| h["CONTENT_LENGTH"] = body.length if !body.nil? }

      env.merge!(headers) if headers
    end
  end
end
