$:.unshift File.dirname(__FILE__) + '/../lib'

require "bundler/setup"
require "minitest/spec"
require "minitest/pride"
require "minitest/autorun"
require "net/ptth"

class Minitest::Spec
  def setup
    Celluloid.shutdown
    Celluloid.boot
  end
end
