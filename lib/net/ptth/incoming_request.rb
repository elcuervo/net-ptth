class Net::PTTH
  IncomingRequest = Struct.new(:method, :path, :headers, :body) do
    def to_env
      env = {
        "PATH_INFO" => path,
        "SCRIPT_NAME" => "",
        "rack.input" => StringIO.new(body || ""),
        "REQUEST_METHOD" => method,
      }

      env["CONTENT_LENGTH"] = body.length unless body.nil?

      env.merge!(headers) if headers

      env
    end
  end
end
