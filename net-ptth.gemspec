Gem::Specification.new do |s|
  s.name         = "net-ptth"
  s.version      = "0.0.17"
  s.summary      = "Net::HTTP compatible reverse HTTP version"
  s.description  = "PTTH Ruby client. Net::HTTP compatible... kind of"
  s.authors      = ["elcuervo"]
  s.email        = ["yo@brunoaguirre.com"]
  s.licenses     = ["MIT", "HUGWARE"]
  s.homepage     = "http://github.com/elcuervo/net-ptth"
  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files test`.split("\n")

  s.required_ruby_version = ">= 2.7.0"

  s.add_dependency("rack",           ">= 1.4.5")
  s.add_dependency("celluloid-io",   ">= 0.15.0")
  s.add_dependency("http_parser.rb", ">= 0.6.0.beta.2")

  s.add_development_dependency("minitest", "~> 4.4.0")
  s.add_development_dependency("cuba", "~> 3.1.0")
  s.add_development_dependency("sinatra", "~> 1.3.3")
end
