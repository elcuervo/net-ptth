Gem::Specification.new do |s|
  s.name         = "net-ptth"
  s.version      = "0.0.1"
  s.summary      = "Net::HTTP compatible reverse HTTP version"
  s.description  = "PTTH Ruby client. Net::HTTP compatible... kind of"
  s.authors      = ["elcuervo"]
  s.email        = ["yo@brunoaguirre.com"]
  s.homepage     = "http://github.com/elcuervo/net-ptth"
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files test`.split("\n")

  s.add_dependency("celluloid-io", "~> 0.12.1")
  s.add_dependency("http-parser-lite", "~> 0.6.0")

  s.add_development_dependency("minitest", "~> 4.4.0")
end
